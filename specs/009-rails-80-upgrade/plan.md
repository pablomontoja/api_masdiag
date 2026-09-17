# Implementation Plan: Rails 7.2 → 8.0 Upgrade

**Branch**: `009-rails-80-upgrade` | **Date**: 2026-08-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-rails-80-upgrade/spec.md`

## Summary

Raise the framework from Rails 7.2.3 to 8.0.5.1 and finish with the 8.0 defaults active, without
changing a single published API response.

Two dependencies block resolution and must be cleared first: `rails-i18n` (bump to the 8.0 line) and
`annotate` (dead gem, final release — replace with the maintained `annotaterb` fork). Ten of the
twelve breaking-change categories in the source guide were verified clean against this codebase
before planning began, including the enum migration the guide calls the most common failure point.

What remains is narrow but not trivial. Three things carry real risk, and none of them are visible
in application code:

1. **The `/jobs` dashboard** is the only asset-serving surface in an API-only app, and `config/`
   contains no asset configuration at all — it inherits entirely from framework defaults, which is
   precisely what 8.0 changes.
2. **`enqueue_after_transaction_commit`** is inherited, not set. It is the framework half of the
   two-layer protection spec 007 built to stop a partner being notified about an uncommitted write.
   Rails 8.0 deprecates the global setting; the constitution explicitly anticipates this moment.
3. **Contract equivalence rests on the test suite with unchanged assertions.** The discipline that
   makes it meaningful — never relax an assertion to make a spec pass — is easy to violate and
   impossible to detect afterwards.

The work is sequenced so a failure is always attributable: blockers, then bump, then verify, then
adopt defaults, then verify again.

## Technical Context

**Language/Version**: Ruby 3.4.10 (unchanged — `required_ruby_version` for Rails 8.0.5.1 is
`>= 3.2.0`, already satisfied by spec 008)

**Primary Dependencies**: Rails 7.2.3 → **8.0.5.1**; `rails-i18n` 7.0.10 → 8.0.x;
`annotate` 3.2.0 → `annotaterb` 4.24.0. Unchanged and verified compatible: `solid_queue` 1.4.0,
`mission_control-jobs` 1.1.0 (already latest), `lockbox` 2.2.0, `alba` 3.10.0, `mysql2` 0.5.7,
`propshaft`, `sentry-rails`, `mobility`, `pundit`.

**Storage**: MySQL — shared `LabSample` (primary) + `solid_queue_db` (queue). **No schema change of
any kind.** Nine sibling applications read these tables.

**Testing**: RSpec, 98 spec files. FactoryBot only, no fixtures. `http_auth_header` for
authenticated request specs.

**Target Platform**: Linux; Docker Compose deployment; `ruby:3.4.10-slim` base image.

**Project Type**: Rails 7 API-only web service (`config.api_only = true`), multi-tenant, 11
namespaces.

**Performance Goals**: None. This is a conservative upgrade — the goal is *unchanged* behaviour,
not improved behaviour. No performance target is asserted or measured.

**Constraints**:
- Zero API contract change across all 11 namespaces (FR-009).
- Zero schema change (FR-020).
- No unrelated gem may move in the lockfile (FR-004).
- Assertions may not be modified to make specs pass (FR-009).
- Verification is local plus staging; no CI exists.

**Scale/Scope**: 11 namespaces, 58 models (39 annotated), 48 background jobs, 98 spec files,
25 `params.require` sites, 6 regex sites, 2 locales.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

Constitution v1.1.1.

| Principle | Assessment | Verdict |
|---|---|---|
| **I. Rails Conventions Over Configuration** | The upgrade *increases* convention alignment by moving to current framework defaults. Namespace separation is untouched — FR-009 requires all 11 namespaces behave identically. | ✅ PASS |
| **II. Service-Object Architecture** | No business logic is written, moved, or restructured. No controller or service changes. | ✅ PASS (N/A) |
| **III. Test-First (NON-NEGOTIABLE)** | Interpreted for an upgrade: the baseline is recorded *before* any change (FR-021), and the suite is the equivalence evidence (FR-009). The strict RED-GREEN cycle does not apply — no new behaviour is authored — but the stronger discipline does: assertions may not be weakened to pass (FR-009). | ✅ PASS |
| **IV. Security & Secrets Discipline** | No credential handling changes. Lockbox round-trip across the upgrade is explicitly verified (FR-015). Dashboard auth re-verified (FR-008b). Target patch 8.0.5.1 is a security release — choosing an earlier patch would work *against* this principle. | ✅ PASS |
| **V. Multi-Tenancy Integrity** | No data-access path changes. FR-010 requires no endpoint become reachable that was previously refused — a direct guard on tenant isolation. | ✅ PASS |
| **VI. Layered Architecture & Abstraction Thresholds** | No new abstractions, no new directories, no code relocation. | ✅ PASS (N/A) |

**Development Workflow compliance**:

- Item 1 (feature branch) — ✅ `009-rails-80-upgrade` created.
- Item 2 (spec before code) — ✅ spec + clarification complete.
- Item 3 (local `bundle exec rspec` is the only gate) — ✅ acknowledged; the plan's verification is
  local + staging, matching the honest statement of the gap in v1.1.1.
- Item 4 (job retry policy; **explicit enqueue-after-commit**) — ✅ **This is the clause the upgrade
  most directly engages.** All 48 jobs verified using `:polynomially_longer`; zero use the removed
  `:exponentially_longer`. FR-014 discharges the requirement that ordering-critical enqueue not rely
  on an inherited default — the constitution says intent must "survive a defaults change", and this
  *is* that defaults change.
- Item 5 (Alba) — ✅ untouched.
- Item 6 (reversible migrations) — ✅ N/A, no migrations.
- Item 7 (`json_response`) — ✅ untouched.
- Item 8 (Constitution Check in plan) — ✅ this section.

**Gate result: PASS.** No violations; Complexity Tracking table omitted as it would be empty.

## Project Structure

### Documentation (this feature)

```text
specs/009-rails-80-upgrade/
├── spec.md                          # Feature spec (28 FR, 19 SC, 5 clarifications)
├── plan.md                          # This file
├── research.md                      # Phase 0 — R1–R10
├── data-model.md                    # Phase 1 — upgrade-state entities
├── quickstart.md                    # Phase 1 — gated execution steps
├── contracts/
│   └── namespace-equivalence.md     # Phase 1 — the 11-namespace contract
├── checklists/
│   └── requirements.md              # Spec quality checklist
└── tasks.md                         # Phase 2 — created by /speckit-tasks, NOT here
```

### Source Code (repository root)

This is an upgrade, not a feature: no new application directories, no new source files. The files
that change are configuration and dependency manifests, plus verification specs.

```text
# Modified — dependency and version manifests
Gemfile                              # rails ~> 8.0.5; rails-i18n 8.0; annotate → annotaterb
Gemfile.lock                         # regenerated; only permitted gems may move (FR-004)

# Modified — framework configuration
config/application.rb                # load_defaults 7.2 → 8.0 (staged, after bump verified)
                                     # + explicit active_job.enqueue_after_transaction_commit (FR-014)
config/initializers/
└── new_framework_defaults_8_0.rb    # created by app:update; reviewed item-by-item (FR-006)

# Verified, expected UNCHANGED — the contract surface
app/controllers/                     # 11 namespaces — no edits expected
app/models/                          # 58 models; 39 annotated (annotation regen deferred, R3)
app/jobs/                            # 48 jobs; all already :polynomially_longer
app/resources/                       # Alba serializers — response shape lives here
db/schema.rb                         # MUST NOT change (FR-020)

# Verification
spec/                                # 98 files; assertions MUST NOT be weakened (FR-009)
```

**Structure Decision**: No structural change. The constitution forbids new directories without an
amendment, and none is needed — this upgrade touches dependency manifests and framework
configuration only. The application layout established in the constitution's Canonical Directory
Structure is preserved exactly.

The one deliberate omission: **`db/schema.rb` is not regenerated.** Rails 8.0 sorts schema columns
alphabetically, which would produce a large cosmetic diff — and in spec 007 a routine
`db:schema:dump` against a stale development database silently deleted two table definitions and
regressed the migration version. FR-020 treats any schema difference as a defect in the upgrade
rather than an outcome of it. See research.md R8.

## Phase Sequencing

The order exists so that any failure is attributable to exactly one change.

| Phase | Content | Gate before proceeding |
|---|---|---|
| **0** | Record baseline; prove blocker set by resolution | Suite green and reproducible (FR-021) |
| **1** | Clear both blockers, still on Rails 7.2.3 | Resolution succeeds; suite reproduces baseline; only permitted gems moved (FR-004) |
| **2** | Bump framework to 8.0.5.1; review `app:update` output item-by-item | App boots; suite green; 11 namespaces pass with unchanged assertions |
| **3** | Verify behaviour: jobs, encryption, dashboard, container | FR-008, FR-008a/b, FR-013, FR-015 all satisfied |
| **4** | Adopt `load_defaults 8.0`; set enqueue-after-commit explicitly | Suite + 11 namespaces verified **a second time**; regex sites checked (FR-017) |
| **5** | Equivalence report, warning review, upgrade record | Another developer can revert or continue from the record alone |

Phase 1 is independently shippable: clearing the blockers is valuable on Rails 7.2 regardless of
whether the framework bump proceeds. Phases 2 and 4 are separated deliberately — that separation is
what makes a defaults-induced failure distinguishable from a bump-induced one, and it is why the
suite and namespaces are verified twice (SC-013a).

## Risk Register

| Risk | Why it is real here | Mitigation |
|---|---|---|
| **`/jobs` dashboard breaks silently** | Only asset-serving surface; zero asset config in `config/`; Rails 8 changes the default pipeline. A broken stylesheet still returns HTTP 200. | FR-008a requires a *render* check, not a reachability check (SC-013b) |
| **Partner notified about uncommitted write** | Irreversible, invisible, and the framework-level guard is inherited rather than explicit | FR-014 (set explicitly) + FR-013 (commit/rollback exercise against a real worker) |
| **An assertion gets relaxed to make a spec pass** | Converts a detected contract change into a silent one; tempting under time pressure | FR-009 treats any assertion change as a finding requiring explanation |
| **Thin coverage overstates equivalence confidence** | Coverage is uneven across the 11 namespaces; a green run implies uniform confidence it has not earned | FR-009a requires naming the thin namespaces in the report |
| **Locale key silently falls back** | `rails-i18n` supplies framework validation messages; a missing key does not raise, it degrades an API error body | FR-002 / SC-012 verify both locales resolve |
| **Annotation regeneration floods the diff** | 39/58 models annotated, no config file, fork defaults differ | R3: swap the gem, defer regeneration; diff before committing anything |
| **Schema silently loses tables** | Happened in spec 007 from a stale dev DB | FR-020: do not regenerate; treat any schema diff as a defect |
| **A third blocker appears at resolution** | Declared-bound scanning cannot find gems that are incompatible without saying so | FR-001 makes resolution the authority; edge case already recorded |
| **Target patch moves before implementation** | 8.0.5.1 today; spec 008 hit exactly this (3.4.9 → 3.4.10) | FR-005: latest-at-implementation, re-checked and recorded |

## Complexity Tracking

Not applicable — the Constitution Check passed with no violations.
