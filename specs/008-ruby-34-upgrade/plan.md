# Implementation Plan: Ruby 3.4 Upgrade

**Branch**: `008-ruby-34-upgrade` | **Date**: 2026-08-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-ruby-34-upgrade/spec.md`

## Summary

Raise the language runtime from Ruby 3.3.7 to **3.4.10**, keeping Rails at 7.2.3. Delivered as
three commits: declare `observer`, change the runtime, verify.

Phase 0 resolved both deferred decisions and produced one correction to the spec's evidence base:

1. **Target 3.4.10, not the trial's 3.4.9.** A newer patch has published since the sandbox run.
   The trial's evidence carries forward (patch releases within a stable minor are compatible), but
   the suite must be re-run on 3.4.10 rather than treating the trial as the verification.
2. **`ruby:3.4.10-slim` exists** and the Dockerfile already parameterises the version, so the image
   change is a single `ARG` edit.

The upgrade itself is small and already proven viable: one dependency declaration, three version
pins, no application code changes. The plan's weight sits in *verification*, not implementation —
specifically in the four things the sandbox trial did **not** prove (container-internal compilation,
3.4.10 specifically, real-worker job behaviour, encrypted-attribute round-trip).

## Technical Context

**Language/Version**: Ruby 3.3.7 → **3.4.10** (pinned in `.ruby-version`, `Gemfile`, `Dockerfile`)

**Primary Dependencies**: Rails 7.2.3 — **unchanged**. `observer` newly declared. All other gems held.

**Storage**: MySQL via `mysql2`, shared LabSample database — **schema must not change**

**Testing**: RSpec + FactoryBot. Baseline: 755 examples, 0 failures

**Target Platform**: Linux; Docker `registry.docker.com/library/ruby:$RUBY_VERSION-slim`; four
environments (development, test, staging, production)

**Project Type**: Rails 7.2 API-only web service, multi-tenant, 9 namespaces

**Performance Goals**: No regression. Suite runtime within 50% of baseline (SC-013)

**Constraints**: No framework version change; no LabSample schema change; API response equivalence;
no unrelated dependency upgrades; fully revertible; no CI — verification is local plus container build

**Scale/Scope**: ~165 gems — 11 source-compiled, 2 precompiled with platform variants (27 lockfile
entries); 1 dependency declaration; 3 version pins; 0 application code changes

## Constitution Check

*GATE: evaluated against constitution v1.1.1 before Phase 0 and re-checked after Phase 1.*

| Principle | Status | Assessment |
|-----------|--------|------------|
| **I. Rails Conventions** | ✅ Pass | No structural change. Namespaces, routing and naming untouched; API-equivalence is an explicit requirement (FR-009). |
| **II. Service-Object Architecture** | ✅ Pass | No application code changes at all. No controller, model or service is modified. |
| **III. Test-First (NON-NEGOTIABLE)** | ✅ Pass | No new behaviour is introduced, so there is nothing to drive with a failing test. The existing 755-example suite is the specification of correct behaviour, and every step is gated on it. Verification tasks that *add* checks (real-worker job behaviour, encryption round-trip) are written before the runtime changes so they capture a genuine before-state. |
| **IV. Security & Secrets** | ✅ Pass | No credential handling changes. Field-level encryption is re-verified on the new runtime (FR-011) rather than assumed — Lockbox 2.2.0 was only ever proven on 3.3.7. |
| **V. Multi-Tenancy Integrity** | ✅ Pass | No data-access path changes. Institution scoping and validation contexts untouched. |
| **VI. Layered Architecture** | ✅ Pass | No new directories, abstractions or layers. The single dependency declaration adds no structure. |

**Gate result: PASS** — no violations, no Complexity Tracking entries required.

**Post-Phase-1 re-check: PASS.** The design adds only a dependency declaration, three version-pin
edits, and verification artifacts. Notably this is the first feature in this sequence with an **empty
Complexity Tracking table** — spec 007 carried two justified notes; this one carries none.

**Note on constitution v1.1.1**: the amendment made during spec 007 is already reflected here — the
retry-policy guidance now names `:polynomially_longer`, which matches the jobs this plan verifies.

## Project Structure

### Documentation (this feature)

```text
specs/008-ruby-34-upgrade/
├── plan.md              # This file
├── research.md          # Phase 0 — target patch, image, trial scope, resolution constraint
├── data-model.md        # Phase 1 — verification records tracked by this change
├── quickstart.md        # Phase 1 — executable steps with gates
├── contracts/
│   └── runtime-compatibility.md   # Phase 1 — what must hold across the runtime change
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 — created by /speckit-tasks, NOT by this command
```

### Source Code (repository root)

Deliberately minimal. Files this plan expects to modify:

```text
Gemfile                  # + gem "observer";  ruby "3.3.7" → "3.4.10"
Gemfile.lock             # + observer;  RUBY VERSION stanza
.ruby-version            # ruby-3.3.7 → ruby-3.4.10
Dockerfile               # ARG RUBY_VERSION=3.3.7 → 3.4.10
```

**No files under `app/`, `lib/`, `config/`, or `db/` are expected to change.** If any such change
appears necessary, that is a signal the upgrade has a compatibility problem the trial did not
surface, and it should be investigated rather than absorbed.

New verification specs (written before the runtime change, to capture a before-state):

```text
spec/models/encryption_round_trip_spec.rb    # NEW — Lockbox decrypt across runtimes
```

**Structure Decision**: Existing layout retained unchanged. No new directories — the constitution
requires an amendment for that, and none is warranted. The single new spec follows the established
`spec/models/` convention.

## Implementation Sequence

Each step is a separate commit with its own gate. Ordering is forced by the resolution constraint in
research R5: `--conservative --update` cannot add a gem, so `observer` must land before the runtime moves.

| # | Step | Story | Gate |
|---|------|-------|------|
| 1 | Record baseline on Ruby 3.3.7 (suite, versions, lockfile) | — | Baseline reproduces on rerun |
| 2 | Scan for other undeclared stdlib requires | US1 (P1) | Every candidate declared or confirmed unused |
| 3 | Write encryption round-trip spec **on 3.3.7** | US2 prep | Passes — captures before-state |
| 4 | Declare `gem "observer"`; plain `bundle lock` | US1 (P1) | Lockfile gains only `observer`; suite green |
| 5 | Install Ruby 3.4.10 (`rvm get stable` first — known-list is stale) | US2 (P2) | `ruby -v` reports 3.4.10 |
| 6 | Update the three version pins | US2 (P2) | All three agree |
| 7 | `bundle install` on 3.4.10 | US2 (P2) | 11 source-compiled gems build; precompiled gems resolve; no unrelated gem moves |
| 8 | Full suite + namespace equivalence | US2 (P2) | ≥755 examples, 0 failures; 8 namespaces match |
| 9 | Encryption round-trip + real-worker job verification | US2 (P2) | Decrypts correctly; commit/rollback paths observed |
| 10 | Build the container image | US2 (P2) | Image builds; application starts |
| 11 | Warning review | US2 (P2) | Each resolved or recorded |
| 12 | Write the upgrade record | US2 (P2) | Another developer can act on it |
| 13 | *(Optional)* `factory_bot` upgrade assessment | US3 (P3) | Recorded upgrade-or-defer decision |

Steps 1–4 run on Ruby 3.3.7 and deliver value even if the runtime change is abandoned.

## Risk Assessment

Lower than spec 007 — no framework behaviour changes, no API surface changes, no schema interaction.
The residual risks are environmental rather than logical:

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Native gem fails to compile **inside the container** | Low–Medium | Trial proved local compilation only, against a different toolchain. Step 10 verifies the image explicitly rather than inferring from step 7. |
| Unrelated dependency drift during lockfile regeneration | Medium | Steps 4 and 7 both gate on the diff containing nothing unexpected. This trap was hit in the trial. |
| `observer` is no longer the only blocker | Low | Step 2 re-scans rather than trusting the trial (FR-002). |
| 3.4.10 behaves differently from the trialled 3.4.9 | Low | Compatible patch within a stable minor, but step 8 re-runs the suite rather than citing the trial. |
| Encrypted data fails to decrypt | Low | Lockbox 2.2.0 was verified on 3.3.7 only. Step 3 writes the check before the change; step 9 re-runs it after. |
| Staging/production boot unverified | Certain | Environmental limit inherited from spec 007 — the DB host is unreachable from this workstation. Recorded as a pre-release action, not closable here. |

## Complexity Tracking

> No Constitution Check violations. This table is intentionally empty.

The feature introduces no new abstractions, no new directories, no layer violations, and no
application code changes whatsoever. Nothing requires justification.
