# Implementation Plan: Rails 7.2 Upgrade

**Branch**: `007-rails-72-upgrade` | **Date**: 2026-08-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-rails-72-upgrade/spec.md`

## Summary

Upgrade `api_masdiag` from Rails 7.1.6 to 7.2.3, keeping Ruby at 3.3.7 and `config.load_defaults` at 7.1, delivered as a sequence of independently verifiable and revertible commits.

Phase 0 resolution testing retired the feature's biggest unknown: **the full dependency graph resolves cleanly on Rails 7.2.3**, git-sourced gem included, so there is no blocker. It also produced two findings that shape the whole approach:

1. **`lockbox` must move to 2.2.0 with Rails, atomically.** The gem's source guard is `if ar_version < 7.2 → raise`, so 2.2.0 requires Active Record ≥ 7.2. The `Gemfile` comment describing the opposite constraint becomes obsolete on upgrade.
2. **The update must be conservative and targeted.** A bare `bundle update` resolves, but sweeps in ~40 unrelated bumps including `rspec-rails` 7→8 and `sentry` 5→6, destroying failure attribution and the rollback guarantee.

The one confirmed behavioural change — a partner-notification job enqueued inside a transaction — is fixed by relocating the call outside the transaction block, which is verifiable on Rails 7.1 *before* the framework moves.

## Technical Context

**Language/Version**: Ruby 3.3.7 (unchanged by this feature; pinned in `.ruby-version`, `Gemfile`, and `Dockerfile`)

**Primary Dependencies**: Rails 7.1.6 → **7.2.3**; Lockbox 1.2.0 → **2.2.0** (forced, see research R2); `csv` and `base64` newly declared. All other gems held at current versions.

**Storage**: MySQL via `mysql2 ~> 0.5`, shared LabSample database — **schema must not change**

**Testing**: RSpec + FactoryBot. Baseline: 737 examples, 0 failures, ~36s

**Target Platform**: Linux; production via Docker (`ARG RUBY_VERSION=3.3.7`), four environments (development, test, staging, production)

**Project Type**: Rails 7 API-only web service, multi-tenant, 9 namespaces

**Performance Goals**: No regression. Suite runtime must stay within 50% of the ~36s baseline (SC-017)

**Constraints**: No LabSample schema change; no Ruby version change; API response equivalence across 8 in-scope namespaces; fully revertible to the 7.1.6 dependency set; no CI — all verification local

**Scale/Scope**: ~176 gems; 9 API namespaces; 1 confirmed behavioural defect; 2 deprecation-cleanup sites; 2 newly declared stdlib gems

## Constitution Check

*GATE: evaluated against constitution v1.1.0 before Phase 0 and re-checked after Phase 1.*

| Principle | Status | Assessment |
|-----------|--------|------------|
| **I. Rails Conventions** | ✅ Pass | The upgrade moves *toward* convention. Namespace separation is untouched — response equivalence is an explicit requirement (FR-015). |
| **II. Service-Object Architecture** | ⚠️ Pass with note | `fv1/kit_controller.rb#assign_tests` currently runs a transaction, three writes, and an external notification inline — over the 15-line threshold and holding business logic. **This plan relocates one call; it does not refactor the action into a service object.** See Complexity Tracking. |
| **III. Test-First (NON-NEGOTIABLE)** | ✅ Pass | Every behavioural change is spec-first: the rollback spec (FR-016) is written and made to fail before the fix; `regspec` smoke checks are written *before* the bump so they yield a real before/after comparison (research R8). |
| **IV. Security & Secrets** | ✅ Pass | No credential handling changes. Lockbox major bump touches patient-data encryption, so decrypt-existing-records verification is an explicit task, not an assumption. |
| **V. Multi-Tenancy Integrity** | ✅ Pass | No data-access path changes. Institution scoping and validation contexts are untouched; namespace equivalence checks guard against accidental drift. |
| **VI. Layered Architecture** | ⚠️ Pass with note | Same note as II — the correct long-term home for the kit-assignment flow is a service object. Deliberately out of scope here. |

**Gate result: PASS.** Two notes recorded in Complexity Tracking; neither is a violation introduced *by* this work.

**Post-Phase-1 re-check: PASS.** The design adds only specs and dependency/config changes. No new directories, no new abstractions, no anti-patterns introduced.

## Project Structure

### Documentation (this feature)

```text
specs/007-rails-72-upgrade/
├── plan.md              # This file
├── research.md          # Phase 0 — resolution testing, lockbox finding, update strategy
├── data-model.md        # Phase 1 — decision records tracked by this upgrade
├── quickstart.md        # Phase 1 — executable step-by-step with verification gates
├── contracts/
│   └── api-equivalence.md   # Phase 1 — the 8-namespace response contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 — created by /speckit-tasks, NOT by this command
```

### Source Code (repository root)

This is an upgrade, not a feature build: it touches configuration and dependencies broadly but application code narrowly. Files this plan expects to modify:

```text
Gemfile                                   # rails 7.1.5→7.2.3; lockbox 1.2.0→2.2.0; +csv +base64
Gemfile.lock                              # conservative targeted resolution only

app/
├── controllers/
│   └── fv1/kit_controller.rb             # move assign_tests_in_lalen_api outside the transaction
└── models/
    └── key_value_db_store.rb             # serialize: positional coder → coder: keyword

config/
├── application.rb                        # load_defaults stays 7.1 (US4); → 7.2 only in US5
└── environments/*.rb                     # reviewed against generated diff; API-only additions declined

db/migrate/20260311113835_toxicology_quant_project.rb   # AR.connection → with_connection (historical)

spec/
├── requests/regspec/                     # NEW — smoke checks, currently zero coverage
│   ├── institutions_spec.rb
│   ├── contractors_spec.rb
│   ├── samples_spec.rb
│   └── patients_spec.rb
├── requests/fv1/kit_assignment_rollback_spec.rb   # NEW — rollback must not notify partner
└── services/hl7/measurement_importer_spec.rb      # AR.connection → with_connection
```

**Structure Decision**: Existing Rails layout is retained unchanged. No new directories — the constitution requires an amendment for that, and none is warranted. New specs follow the established `spec/requests/<namespace>/` convention. The only structural addition is `spec/requests/regspec/`, which mirrors existing namespace spec directories.

## Implementation Sequence

Each step is a separate commit, independently revertible, with its own verification gate. Ordering is derived from the spec's story priorities and the sequencing constraint in research R5.

| # | Step | Story | Gate |
|---|------|-------|------|
| 1 | Record baseline: suite result, versions, lockfile snapshot | US1 (P1) | Baseline reproduces on rerun |
| 2 | Re-verify the 12-item Breaking-Change Audit against the working tree | US1 (P1) | Every entry confirmed or corrected |
| 3 | Declare `csv` + `base64`; plain `bundle lock` **on Rails 7.1** | US2 (P1) | Lockfile gains only `csv`; suite green |
| 4 | Write `regspec` smoke checks **on Rails 7.1** | US4 prep | New specs pass; before-state captured |
| 5 | Write failing rollback spec for kit assignment | US3 (P2) | Spec fails for the right reason |
| 6 | Move `assign_tests_in_lalen_api` outside the transaction | US3 (P2) | Rollback spec passes; suite green — still on 7.1 |
| 7 | Bump Rails → 7.2.3 **and** lockbox → 2.2.0; conservative targeted update | US4 (P3) | Graph resolves; only Rails stack + lockbox move |
| 8 | Boot all four environments; run suite; compare namespace responses | US4 (P3) | Suite green; 8 namespaces equivalent |
| 9 | Deprecation cleanup: `serialize` keyword, `AR.connection` → `with_connection` | US4 (P3) | Warnings resolved or recorded |
| 10 | Verify locally against a real Solid Queue worker (commit + rollback paths) | US4 (P3) | Both paths observed, not inferred |
| 11 | Review generated config diff; decline full-stack additions | US5 (P4) | Every difference has a decision |
| 12 | *(Optional, deferrable)* `load_defaults` → 7.2 with per-default decisions | US5 (P4) | Suite green; each default recorded |

Steps 1–6 run entirely on Rails 7.1 and deliver value even if the upgrade is abandoned at step 7.

## Complexity Tracking

> Notes recorded for transparency. Neither is a violation *introduced* by this work; both are pre-existing conditions this plan deliberately declines to fix.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `fv1/kit_controller.rb#assign_tests` exceeds the 15-line controller threshold and holds business logic (transaction + external notification), contrary to Principles II & VI | The action is pre-existing. This plan relocates exactly one call to fix a data-consistency defect. Extracting the whole flow into a service object would enlarge an upgrade diff into a refactor, defeating the attribution and rollback guarantees (FR-023) that the entire plan is built around. | Refactoring to a service object now was rejected because it couples an upgrade to a behavioural rewrite of a partner-facing endpoint. It is the right follow-up, and should be its own spec once 7.2 is stable. |
| Lockbox major version bump (1.2.0 → 2.2.0) inside an upgrade whose stated principle is one-variable-at-a-time | Not optional and not separable: Lockbox 2.2.0 raises unless Active Record ≥ 7.2, and 1.2.0 is the supported version below it. The two versions have disjoint supported ranges, so they must move together in one commit. | Bumping lockbox separately is impossible in both directions. Staying on 1.2.0 under Rails 7.2 is an unsupported combination the maintainer's own guard signals against. Mitigated by explicit decrypt-existing-records verification. |
