# Research: Lalen Assign Kit Tests

**Feature**: `004-lalen-assign-kit-tests`
**Date**: 2026-06-24

## Decision 1: Job argument strategy — pass barcode + api_key list vs. pass ReservedSampleCode ID

**Decision**: Pass `barcode` (String) and `api_keys` (Array of String) as plain job arguments at enqueue time.

**Rationale**: The spec requires fault isolation between the local assignment and the external notification. If the job re-queries the database at execution time, a subsequent assignment (which replaces all tests) could race with job execution and send a stale payload. Passing primitive arguments at enqueue time captures the intended state deterministically. This also mirrors the argument shape of the external API endpoint (`barcode` + `tests` array).

**Alternatives considered**: Passing the `ReservedSampleCode` record directly (as `RegisterKitJob` does with `sample`) — rejected because ActiveJob serialises AR objects by primary key and re-queries at execution, creating the stale-data race described above.

---

## Decision 2: api_key slug mapping — where does the translation live?

**Decision**: A constant `V1::Common::LALEN_TEST_API_KEYS` maps Lalen `api_key` slug → local `project_id`. This is stored as the "api_key → project_id" direction (matching the external system as the source of truth). The job receives the resolved `api_key` strings as arguments — it does NOT perform any mapping itself.

**Rationale**: The actual mapping was confirmed from `Test.all.pluck(:api_key, :masdiag_api_test_id)` on the Lalen portal database. The mapping is **many-to-one** in the project_id direction — e.g., `vitamin-e`, `vitamin-a`, and `coq10` all map to local project_id 10; `omega-3-complete`, `omega-3-basic`, `omega-3-plus`, and `prenatal-dha` all map to project_id 21. This means we cannot safely invert the map (one project_id → many possible api_keys). The correct api_key must be passed explicitly as a job argument from the enqueue site, not derived from the project_id at runtime.

**Confirmed mapping** (only 5 tests used, strictly 1-to-1):

| Lalen api_key       | Local project_id |
|---------------------|-----------------|
| `vitamin-d`         | 22              |
| `omega-3-basic`     | 21              |
| `hba1c`             | 23              |
| `homocysteine`      | 12              |
| `glutathione-index` | 26              |

The mapping is safely invertible — no duplicate project_ids. The constant is stored as `api_key → project_id`; `project_id` can be derived unambiguously by lookup.

**Impact on `assign_tests` flow**: The action is updated to accept `api_keys` (string array) instead of integer `test_ids`. It validates against `LALEN_TEST_API_KEYS.keys`, resolves project_ids, saves `ReservedTest` records, then enqueues the job with the api_keys array.

**Alternatives considered**: Adding `api_key` column to `Project` model — over-engineering, requires migration, out of scope.

---

## Decision 3: HTTP endpoint path on external Lalen API

**Decision**: The external endpoint is `POST /kit_tests` on the Lalen portal API, based on the `KitTestsController` reference provided in the feature description. The route follows REST convention for that controller's `create` action.

**Rationale**: The `KitTestsController` docs specify: request body `{ barcode: String, tests: Array<String> }`, success `201`. The `LalenApi::Client` already points to the correct base URL. The path `kit_tests` follows the Rails resourceful default for `KitTestsController`.

**Alternatives considered**: Path `assign_kit_tests` or `kits/:barcode/tests` — no evidence for these; REST default is the safe assumption.

---

## Decision 4: Retry configuration

**Decision**: Use `retry_on StandardError, wait: :exponentially_longer, attempts: 10` — identical to `RegisterKitJob`.

**Rationale**: Consistency with existing Lalen integration. 10 attempts with exponential backoff provides substantial resilience for transient external API failures without requiring configuration changes.

**Alternatives considered**: Fewer attempts — no reason to diverge from the established pattern.

---

## Decision 5: Error handling — 404 response from external API

**Decision**: Mirror `RegisterKitJob`'s pattern: `return if response.status == 404` (treat as silent no-op), raise `LalenApi::Error` for any other non-201 status.

**Rationale**: The existing job silently ignores 404 from the external API (kit not found on their side), which is a valid "nothing to do" state. The same logic applies for test assignment.

**Alternatives considered**: Always raising on non-201 — would cause unnecessary retries for permanent "not found" conditions on the external system.

---

## Existing Codebase Findings

| File | Role |
|------|------|
| `app/jobs/lalen_api/register_kit_job.rb` | Reference implementation for the new job |
| `app/models/lalen_api/register_kit.rb` | Reference ActiveModel value object for the new `KitTests` value object |
| `app/services/lalen_api/client.rb` | Singleton Faraday connection — reused unchanged |
| `app/models/lalen_api/error.rb` | Custom error class — reused unchanged |
| `app/controllers/lalen/kit_controller.rb` | Enqueue site — `assign_tests` action to be modified |
| `app/lib/v1/common.rb` | `AVAILABLE_TESTS` constant (id, name, material, weight) — api_key mapping to be added here |
| `spec/jobs/contractor_results_notifier_job_spec.rb` | Reference test pattern for job specs |
