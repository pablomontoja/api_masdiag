# Contract: Namespace Equivalence

**Feature**: 009-rails-80-upgrade | **Date**: 2026-08-18

The contract this upgrade must not break. `api_masdiag` is consumed by nine sibling applications and
two external partners; a changed response is a production incident at a diagnostic laboratory, and a
partner integration cannot be corrected from our side alone.

## The rule

> Equivalence means **the same request specs pass with unchanged assertions**.

An assertion modified to make a spec pass after the upgrade converts a *detected* contract change
into a *silent* one. Any assertion requiring modification is escalated as a finding and the
underlying behavioural difference explained **before** the spec is touched (FR-009).

This is the single most important discipline in the upgrade — the one that is easiest to violate
under time pressure and impossible to detect afterwards.

## What must hold, per namespace

| Property | Requirement |
|---|---|
| Response body | Byte-identical for equivalent requests |
| Status code | Identical, success and failure alike |
| Error shape | Identical structure and field naming |
| Authentication | Valid admitted, invalid refused — identically |
| Reachability | No endpoint newly reachable that was previously refused |
| Parameter rejection | Same malformed/missing inputs rejected, same reasons, same codes |

## Coverage inventory

Measured from `spec/requests/` on 2026-08-18. This is the honest picture the equivalence report must
carry (FR-009a) — coverage is **not** uniform, and a green suite does not imply uniform confidence.

| Namespace | Spec files | Location | Coverage assessment |
|---|---:|---|---|
| `v1` | 8 | `spec/requests/v1_*.rb` | **Strong** — create, destroy, kit assign, result, setup, code check, pool status |
| `fv1` | 8 | `spec/requests/fv1_*.rb` + `fv1/` | **Strong** — includes the 007 rollback guard. Partner-facing |
| `nume` | 7 | `spec/requests/nume_*.rb` | **Strong** |
| `toxo` | 9 | `spec/requests/toxo/` | **Strong** |
| `regspec` | 4 | `spec/requests/regspec/` | **Adequate** — added by spec 007 (was zero) |
| `masdiag` | 4 | `spec/requests/masdiag/` | **Adequate** |
| `lalen` | 2 | `spec/requests/lalen*` | **Thin** — partner-facing. Flag in report |
| `masdiag_mailer` | 1 | `spec/requests/masdiag_mailer/` | **Thin** — flag in report |
| `webhook` | 1 | `spec/requests/api/webhook/` | **Thin** — flag in report |
| `diagnostyka_precyzyjna` | 1 | `spec/requests/dp_shop_orders_spec.rb` | **Thin** — flag in report |
| `patient_portal` | **0** | — | **None** — structural verification only (see below) |

**Four namespaces are thin and one has no coverage at all.** For these, "the suite passes" is a weak
claim and must be reported as such rather than folded into a green summary.

`lalen` deserves particular attention: it is partner-facing with only two spec files, and it is the
namespace whose partner-notification ordering spec 007 had to fix.

### `patient_portal`

Excluded from behavioural comparison per the clarification recorded in spec 007 — currently unused,
implementation may change. **Structural verification still applies**: routes must load and the
application must boot with the namespace mounted. It must not become reachable without
authentication (FR-010).

## Verification procedure

Run per namespace rather than as one suite, so a failure localises immediately:

```bash
bundle exec rspec spec/requests/v1_*.rb
bundle exec rspec spec/requests/fv1_*.rb spec/requests/fv1/
bundle exec rspec spec/requests/nume_*.rb
bundle exec rspec spec/requests/toxo/
bundle exec rspec spec/requests/regspec/
bundle exec rspec spec/requests/masdiag/
bundle exec rspec spec/requests/lalen*
bundle exec rspec spec/requests/masdiag_mailer/
bundle exec rspec spec/requests/api/webhook/
bundle exec rspec spec/requests/dp_shop_orders_spec.rb
```

Run **twice**: once after the framework bump with defaults still at 7.2, and once after adopting
`load_defaults 8.0` (SC-013a). The two runs are what make a defaults-induced failure
distinguishable from a bump-induced one.

## The `/jobs` dashboard

Not a namespace, but part of the surface that must survive — and the least obvious risk in the
upgrade.

`MissionControl::Jobs::Engine` is mounted at `/jobs` (`config/routes.rb:235`). It is the **only
asset-serving surface** in an API-only application, and `config/` contains **no asset configuration
at all** — so it inherits entirely from framework defaults, which Rails 8.0 changes.

| Check | Requirement |
|---|---|
| Renders | Page loads with styling and scripts working — **not** merely HTTP 200 (FR-008a) |
| Authentication | Valid credentials admitted, invalid refused, never reachable unauthenticated (FR-008b) |

A broken stylesheet returns 200 for the page itself. A reachability check passes while the dashboard
is unusable, which is why FR-008a demands an actual render.

`AdminController` — the dashboard's base controller, per
`config.mission_control.jobs.base_controller_class` — authenticates via
`http_basic_authenticate_with` reading Rails credentials. This is the class that raised
`ArgumentError` in the container when credentials were unreadable, so the container check (FR-008)
is where a credentials-related regression would surface.

## Reporting

The equivalence report records, per namespace: specs exercised, pass/fail, coverage assessment, and
**whether that coverage substantiates the equivalence claim**. Namespaces marked Thin or None are
named explicitly, so residual risk is visible at deployment time instead of being discovered by a
partner.
