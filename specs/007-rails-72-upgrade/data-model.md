# Phase 1 Data Model: Rails 7.2 Upgrade

**Feature**: 007-rails-72-upgrade | **Date**: 2026-08-17

## Scope note

This upgrade introduces **no database entities and no schema changes**. The shared LabSample schema is explicitly out of bounds (FR-018, SC-009), since other apps in the ecosystem read the same tables.

The "entities" below are therefore **decision and verification records** — the artifacts the upgrade produces to satisfy its own auditability requirements (FR-034). They are documents, not tables. Where they live is a planning choice; the requirement is that they exist and are complete.

---

## E1 — Baseline Record

Captured once, before any change. The reference for every later comparison.

| Field | Value at planning time | Notes |
|-------|------------------------|-------|
| `rails_version` | 7.1.6 | From `Gemfile.lock` |
| `ruby_version` | 3.3.7 | Must match across 3 pin locations |
| `load_defaults` | 7.1 | `config/application.rb:24` |
| `example_count` | 737 | Must not decrease (SC-007) |
| `failure_count` | 0 | Must remain 0 |
| `runtime_seconds` | ~36 | +50% ceiling (SC-017) |
| `lockfile_digest` | — | Enables exact revert (SC-014) |

**Invariant**: reverting to `lockfile_digest` must reproduce `example_count` / `failure_count` exactly.

---

## E2 — Dependency Compatibility Verdict

One per gem in the lockfile (~176). Resolved wholesale by the Phase 0 resolution test rather than gem-by-gem.

| Field | Description |
|-------|-------------|
| `gem_name` | Identifier |
| `current_version` | From baseline lockfile |
| `target_version` | After conservative targeted update |
| `verdict` | `compatible` / `needs-bump` / `unknown-manual` / `blocking` |
| `evidence` | How determined |
| `action` | What to do |

**Verdicts established in Phase 0:**

| Gem | Current | Target | Verdict | Evidence |
|-----|---------|--------|---------|----------|
| `rails` (+ 11 components) | 7.1.6 | 7.2.3 | needs-bump | Resolution test |
| `lockbox` | 1.2.0 | **2.2.0** | **needs-bump (forced)** | Source guard `ar_version < 7.2 → raise` |
| `csv` | *(undeclared)* | 3.3.6 | needs-declaration | Required by 6 files, absent from Gemfile |
| `base64` | *(transitive)* | 0.3.0 | needs-declaration | Required by 1 file, absent from Gemfile |
| `useragent` | — | 0.16.11 | new transitive | Pulled by Rails 7.2 stack |
| `k-php-serialize` | git | git | **compatible** | Resolved cleanly despite being unassessable by tooling |
| All others (~160) | — | *unchanged* | compatible | Held by conservative update |

**Zero blocking verdicts** — FR-006's blocked-upgrade path is not triggered.

---

## E3 — Breaking-Change Finding

One per documented 7.1→7.2 change (12 total). Recorded in the spec's Breaking-Change Audit; re-verified at execution (FR-007).

| Field | Description |
|-------|-------------|
| `change_id` | 1–12 |
| `priority` | High / Medium |
| `applies` | Whether present in this codebase |
| `locations` | Concrete file:line references |
| `status` | `not-applicable` / `already-compliant` / `pending` / `remediated` |
| `reverified_at` | Execution-time confirmation |

**Distribution**: 6 not-applicable · 2 already-compliant · 3 pending-cleanup · **1 pending-behavioural-fix** (change #1).

---

## E4 — Enqueue-Timing Decision

One per location where a job is enqueued inside a transaction. Exactly one exists.

| Field | Value |
|-------|-------|
| `location` | `app/controllers/fv1/kit_controller.rb:45` |
| `job` | `LalenApi::AssignKitTestsJob` |
| `workflow` | Kit test assignment, Lalen/FFTB partner (institution 83) |
| `external_effect` | **Yes** — POSTs kit barcode to partner API |
| `retry_policy` | 10 attempts, polynomial backoff |
| `required_timing` | **After commit** |
| `rollback_outcome` | Partner not notified; no retries |
| `mechanism` | Relocate call outside transaction block *and* rely on the 7.2 default |
| `verification` | Dedicated rollback spec (FR-016) + real-worker observation (FR-033) |

**State transitions of the workflow:**

```
assignment requested
      │
      ▼
  transaction opens
      │  destroy existing reserved_tests
      │  create new reserved_tests
      │  update reserved_sample_code
      ▼
  ┌───────────────┬──────────────────┐
  │   COMMIT      │    ROLLBACK      │
  ▼               ▼                  │
notify partner   partner NOT notified
(exactly once)   (no enqueue, no retries)
```

The left path is current behaviour *when nothing goes wrong*; the right path is what is currently broken and what this upgrade fixes.

---

## E5 — Framework Default Decision

One per new 7.2 default. Populated during User Story 5 (P4) from the generated configuration diff — deliberately not enumerated here, since the set varies by patch release (research, residual unknowns).

| Field | Description |
|-------|-------------|
| `default_name` | Configuration key |
| `effect` | What changes |
| `decision` | `adopt` / `override` |
| `rationale` | Required in both cases (FR-024, FR-025) |
| `api_visible` | Whether it alters externally visible behaviour (FR-026) |

**Pre-committed decision**: full-stack-oriented additions (browser-version guard, PWA scaffolding, DevContainers) are declined — this is an API-only application (FR-022, SC-013).

---

## E6 — Deferred Item

Anything knowingly not done.

| Item | Why deferred | Revisit trigger |
|------|--------------|-----------------|
| Ruby 3.4 upgrade | One variable at a time; 3.3 supported well past this work | After 7.2 is stable — separate spec |
| `load_defaults` → 7.2 | Highest behaviour-change risk per line; not required for a shippable 7.2 | Step 12, optional |
| Extracting `kit_controller#assign_tests` to a service object | Would turn an upgrade into a refactor of a partner-facing endpoint | Own spec, after 7.2 stable |
| CI setup | Out of scope; all verification is local | Raised separately |
| `patient_portal` verification | Dormant, 2 read-only endpoints, implementation expected to change | If it returns to active use |
| Two legacy hash-syntax enums | Only if 7.2 actually requires it | Step 2 re-verification |
| Reconciling historical partner notifications | Business data question, not a code question | Business decision |
