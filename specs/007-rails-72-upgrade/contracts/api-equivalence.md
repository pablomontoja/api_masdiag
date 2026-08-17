# Contract: API Response Equivalence Across the Upgrade

**Feature**: 007-rails-72-upgrade | **Date**: 2026-08-17

## What this contract asserts

This upgrade defines **no new API surface**. The contract is the inverse of a normal feature contract: it asserts that the existing surface is *unchanged*.

For every in-scope endpoint, given an identical authenticated request, Rails 7.2.3 must return a response whose **HTTP status and body structure** are identical to those produced by Rails 7.1.6.

This matters more here than in a typical app: `api_masdiag` is the ecosystem's central API, and consuming apps run Ruby 2.7–3.2 with several past EOL. A response-shape drift would break consumers that cannot be quickly patched.

## Scope

**In scope — 8 namespaces:**

| Namespace | Purpose | Existing request specs |
|-----------|---------|------------------------|
| `v1/` | Polish domestic labs | 16 |
| `fv1/` | Foreign institutions | 7 |
| `nume/` | NUME lab system | 7 |
| `lalen/` | Lalen partner | 4 |
| `masdiag/` | Internal Masdiag ops | 17 |
| `masdiag_mailer/` | Email notification endpoints | 7 |
| `regspec/` | REGSPEC system | **0 — must be created** |
| `webhook/` | M2M webhooks (Bearer, no ApiAccount) | 1 |

**Out of scope — 1 namespace:**

| Namespace | Reason |
|-----------|--------|
| `patient_portal/` | Dormant. Two read-only index endpoints (`results#index`, `samples#index`), not currently in use, implementation expected to change. Excluded by clarification 2026-08-17. Verifying it would test behaviour due to be replaced. |

## Equivalence definition

Two responses are equivalent when:

1. **HTTP status matches exactly.**
2. **Body structure matches** — same keys, same nesting, same types, same array ordering semantics.
3. **Error responses match** — the `ExceptionHandler` concern's 404/422 JSON shape is part of the contract, not incidental.
4. **Auth failures match** — an unauthenticated or unauthorized request must fail the same way, with the same status.

Volatile values (timestamps, generated ids, record counts that depend on test data) are **not** part of the contract. Structure and status are.

## The `regspec` gap and how it is closed

`regspec` has zero request specs today, so SC-008 is unverifiable for it as things stand. It is also the namespace where a regression would be most damaging: seven **write** endpoints persisting to shared LabSample tables on behalf of a consuming application.

Endpoints requiring smoke coverage (all `include MasdiagCheck`, i.e. `institution_id == 1`):

| Endpoint | Verb | Controller |
|----------|------|------------|
| `/regspec/institutions` | POST | `Regspec::InstitutionsController#create` |
| `/regspec/institutions/:id` | PATCH/PUT | `Regspec::InstitutionsController#update` |
| `/regspec/contractors` | POST | `Regspec::ContractorsController#create` |
| `/regspec/contractors/:id` | PATCH/PUT | `Regspec::ContractorsController#update` |
| `/regspec/samples` | POST | `Regspec::SamplesController#create` |
| `/regspec/samples/:id` | PATCH/PUT | `Regspec::SamplesController#update` |
| `/regspec/patients/:id` | PATCH/PUT | `Regspec::PatientsController#update` |

**Timing requirement (critical)**: these specs must be written and passing **on Rails 7.1, before the version bump**. Written afterwards, they would only document post-upgrade behaviour and could not detect a change — they would prove nothing. This is why the plan places them at step 4, ahead of step 7.

**Depth**: smoke level. One success path and one auth-failure path per endpoint, asserting status and body shape. Full behavioural coverage of `regspec` is a separate concern and explicitly not part of this upgrade.

## Behavioural contract change (the one intentional difference)

Exactly one externally observable behaviour changes, deliberately:

**Kit assignment — `POST /fv1/kit/...` (institution 83 / FFTB only)**

| | Before | After |
|---|--------|-------|
| Transaction commits | Partner notified | Partner notified *(unchanged)* |
| Transaction rolls back | **Partner notified anyway, retried up to 10×** | **Partner not notified at all** |

The HTTP response to the *caller* is unchanged in both cases. What changes is whether a downstream partner system receives a notification for an assignment that was never persisted. This is a defect fix, recorded as an intentional change per FR-026.

## Verification method

Given no CI and local-only verification (clarified 2026-08-17):

1. **Before the bump** — run the full suite on 7.1.6 with `regspec` smoke checks present; record results as the baseline.
2. **After the bump** — rerun; every previously passing example must still pass, with no reduction in count.
3. **Job-timing paths** — exercised deliberately against a running Solid Queue worker, both commit and rollback. The test environment's in-memory `:test` adapter cannot demonstrate post-commit timing, so this cannot be delegated to the suite.
4. **Encryption** — confirm Lockbox-encrypted attributes written under 1.2.0 still decrypt under 2.2.0. A major bump on the library protecting patient data warrants explicit confirmation rather than inference from a green suite.
