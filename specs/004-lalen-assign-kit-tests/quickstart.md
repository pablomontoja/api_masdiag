# Quickstart: Lalen Assign Kit Tests

## What is being built

A background job `LalenApi::AssignKitTestsJob` that notifies the external Lalen portal API whenever a Lalen partner successfully assigns tests to a kit in this system.

## New files to create

| File | Purpose |
|------|---------|
| `app/jobs/lalen_api/assign_kit_tests_job.rb` | The background job |
| `app/models/lalen_api/kit_tests.rb` | ActiveModel value object for the API payload |
| `spec/jobs/lalen_api/assign_kit_tests_job_spec.rb` | RSpec job spec (write first — TDD) |

## Existing files to modify

| File | Change |
|------|--------|
| `app/controllers/lalen/kit_controller.rb` | Enqueue `AssignKitTestsJob` after `assign_tests` transaction commits |
| `app/lib/v1/common.rb` | Add `LALEN_TEST_API_KEYS` mapping constant |

## Implementation order (TDD)

1. **Write the spec first** — `spec/jobs/lalen_api/assign_kit_tests_job_spec.rb`
   - Test: job is in `background` queue
   - Test: successful POST to external API → job completes
   - Test: 404 response → job returns silently (no raise)
   - Test: non-201/404 response → raises `LalenApi::Error`
   - Test: invalid arguments (blank barcode / empty tests) → raises before HTTP call

2. **Create the value object** — `app/models/lalen_api/kit_tests.rb`
   - Mirror `LalenApi::RegisterKit`
   - Attributes: `barcode` (String), `tests` (Array — use custom attribute type or plain ruby)
   - Validations: `barcode` presence, `tests` presence and non-empty

3. **Create the job** — `app/jobs/lalen_api/assign_kit_tests_job.rb`
   - `retry_on StandardError, wait: :exponentially_longer, attempts: 10`
   - Sentry capture in the retry block
   - Build `LalenApi::KitTests`, validate, POST, handle 404 / non-201

4. **Add the mapping constant** — `app/lib/v1/common.rb`
   - Add `LALEN_TEST_API_KEYS` hash (confirm slug strings against external API docs)

5. **Wire the enqueue** — `app/controllers/lalen/kit_controller.rb`
   - After the `assign_tests` transaction block, map `assignment_params[:test_ids]` through `LALEN_TEST_API_KEYS` and enqueue

## Key reference files

- `app/jobs/lalen_api/register_kit_job.rb` — copy structure verbatim, adapt payload
- `app/models/lalen_api/register_kit.rb` — copy structure for value object
- `spec/jobs/contractor_results_notifier_job_spec.rb` — reference job spec style

## Verification

```bash
# Run the new spec
bundle exec rspec spec/jobs/lalen_api/assign_kit_tests_job_spec.rb

# Run full suite to check for regressions
bundle exec rspec
```

## Important constraints

- The job **must not** re-query tests from the database at execution time — receive `api_keys` as a job argument.
- Enqueue happens **outside** the transaction block in `assign_tests` — never inside a transaction.
- The `api_key` slugs are **confirmed** from the Lalen portal API: see `V1::Common::LALEN_TEST_API_KEYS` in `data-model.md`.
- The mapping is **many-to-one** (multiple Lalen api_keys → same local project_id). Do NOT invert the map to derive api_keys from project_ids — the api_key must come from the request.
- **Backward compatibility**: the current `assign_tests` action takes integer `test_ids`. Confirm with the team whether changing to `api_keys` (strings) breaks existing callers before modifying the request params.
