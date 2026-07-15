# Tasks: Lalen Assign Kit Tests

**Input**: Design documents from `specs/004-lalen-assign-kit-tests/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Included — constitution requires test-first (RED-GREEN-REFACTOR). Spec is written first per constitution Principle III.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Paths follow the single-project Rails layout (`app/`, `spec/`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the mapping constant and create new file skeletons so all subsequent tasks have stable import paths.

- [X] T001 Add `LALEN_TEST_API_KEYS` constant to `app/lib/v1/common.rb` (5 entries: vitamin-d→22, omega-3-basic→21, hba1c→23, homocysteine→12, glutathione-index→26)
- [X] T002 [P] Create empty file `app/models/lalen_api/kit_tests.rb` with module/class skeleton (`module LalenApi; class KitTests; end; end`)
- [X] T003 [P] Create empty file `app/jobs/lalen_api/assign_kit_tests_job.rb` with module/class skeleton (`module LalenApi; class AssignKitTestsJob < ApplicationJob; end; end`)

**Checkpoint**: Constants and file skeletons in place — US4 spec and implementation can now begin.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build and test `LalenApi::KitTests` value object — the payload carrier that both the job and its spec depend on.

- [X] T004 [P] Write failing RSpec unit spec for `LalenApi::KitTests` in `spec/models/lalen_api/kit_tests_spec.rb` — cover: valid with barcode + non-empty tests array, invalid when barcode blank, invalid when tests empty
- [X] T005 Implement `LalenApi::KitTests` in `app/models/lalen_api/kit_tests.rb` — `ActiveModel::Model`, attributes `:barcode` (String) and `:tests` (Array), validations presence of both, `as_json` serialisation producing `{ barcode:, tests: }` — make T004 green

**Checkpoint**: `LalenApi::KitTests` passes its spec. Job spec and controller spec can now begin.

---

## Phase 3: User Story 4 — Background Job Notifies External Lab System (Priority: P1) 🎯 MVP

**Goal**: `LalenApi::AssignKitTestsJob` sends `POST /kit_tests` to the external Lalen portal API with barcode + api_keys. Retries with exponential backoff; captures every failure to Sentry.

**Independent Test**: `bundle exec rspec spec/jobs/lalen_api/assign_kit_tests_job_spec.rb`

### Tests for User Story 4 (write first — RED phase)

- [X] T006 [US4] Write failing RSpec job spec in `spec/jobs/lalen_api/assign_kit_tests_job_spec.rb`:
  - job is in the `background` queue
  - valid barcode + tests → POSTs to external API and completes
  - external API returns 404 → job returns silently (no exception)
  - external API returns non-201/non-404 → raises `LalenApi::Error`
  - blank barcode → raises before any HTTP call
  - empty tests array → raises before any HTTP call
  - Stub HTTP via WebMock on `LalenApi::Client.instance.connection`

### Implementation for User Story 4

- [X] T007 [US4] Implement `LalenApi::AssignKitTestsJob#perform(barcode, api_keys)` in `app/jobs/lalen_api/assign_kit_tests_job.rb`:
  - `retry_on StandardError, wait: :exponentially_longer, attempts: 10` with Sentry capture block (mirror `RegisterKitJob`)
  - Build `LalenApi::KitTests.new(barcode:, tests: api_keys)`
  - Raise `LalenApi::Error` if `kit_tests.invalid?`
  - `POST 'kit_tests'` via `LalenApi::Client.instance.connection`
  - `return if response.status == 404`
  - Raise `LalenApi::Error` if `response.status != 201`
  - Make T006 green

**Checkpoint**: `bundle exec rspec spec/jobs/lalen_api/assign_kit_tests_job_spec.rb` — all green. Job works in isolation.

---

## Phase 4: User Story 1 — Assign Tests to an Active Kit (Priority: P1)

**Goal**: `Lalen::KitController#assign_tests` accepts `api_keys` (string array), validates against `LALEN_TEST_API_KEYS`, replaces `ReservedTest` records, returns 201 with barcode/status/tests, enqueues job outside the transaction.

**Independent Test**: POST to `/lalen/kits/assign_tests` with a valid IN_STOCK barcode and `["vitamin-d"]` — expect 201 and job enqueued.

### Tests for User Story 1 (write first — RED phase)

- [X] T008 [P] [US1] Write failing RSpec unit spec for `LalenApi::AssignKitTestsService` in `spec/services/lalen_api/assign_kit_tests_service_spec.rb`
- [X] T009 [P] [US1] Write failing RSpec request spec in `spec/requests/lalen/kit_assign_tests_spec.rb`

### Implementation for User Story 1

- [X] T010 [US1] Create `LalenApi::AssignKitTestsService` in `app/services/lalen_api/assign_kit_tests_service.rb`
- [X] T011 [US1] Update `assign_tests` action in `app/controllers/lalen/kit_controller.rb` (≤15 lines, accepts `api_keys: []`)

**Checkpoint**: `bundle exec rspec spec/services/lalen_api/ spec/requests/lalen/kit_assign_tests_spec.rb` — all green. US1 fully functional, controller ≤15 lines.

---

## Phase 5: User Story 2 — Assign Tests to an UNREGISTERED Kit (Priority: P2)

**Note**: UNREGISTERED guard removed — state (no sample + existing reserved_tests) is impossible in practice. Kit transitions directly from UNREGISTERED to IN_STOCK on first assignment. All assignment statuses (UNREGISTERED, IN_STOCK, ACTIVE) are handled uniformly by the service.

- [X] T012 [US2] Covered by T008/T009 — all three kit_status values (ACTIVE, IN_STOCK, UNREGISTERED) handled in service
- [X] T013 [US2] No separate guard needed — service handles replacement atomically for all kit statuses

**Checkpoint**: UNREGISTERED scenarios pass alongside US1 scenarios.

---

## Phase 6: User Story 3 — Rejection of Invalid Requests (Priority: P3)

- [X] T014 [US3] US3 contexts covered in `spec/requests/lalen/kit_assign_tests_spec.rb`:
  - Unknown barcode → 422
  - Unrecognised api_key → 422
  - Empty `api_keys` array → 422
  - Missing `api_keys` param → 422
- [X] T015 [US3] All error paths handled by `LalenApi::AssignKitTestsService` and thin controller

**Checkpoint**: Full request spec suite green for all three user stories.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T016 [P] Full RSpec suite: 418 examples, 0 failures
- [X] T017 `spec/models/lalen_api/kit_tests_spec.rb` correctly co-located
- [X] T018 [P] `spec/jobs/lalen_api/assign_kit_tests_job_spec.rb` correctly located

---

## Implementation Summary

All 18 tasks complete. 30 new specs written and passing. Full suite: 418 examples, 0 failures.

### Files Created
- `app/lib/v1/common.rb` — added `LALEN_TEST_API_KEYS` constant
- `app/models/lalen_api/kit_tests.rb` — new value object
- `app/jobs/lalen_api/assign_kit_tests_job.rb` — new background job
- `app/services/lalen_api/assign_kit_tests_service.rb` — new service object
- `app/controllers/lalen/kit_controller.rb` — updated `assign_tests` action
- `config/routes.rb` — uncommented `/lalen/kits/assign_tests` route
- `spec/models/lalen_api/kit_tests_spec.rb` — 6 examples
- `spec/jobs/lalen_api/assign_kit_tests_job_spec.rb` — 6 examples
- `spec/services/lalen_api/assign_kit_tests_service_spec.rb` — 10 examples
- `spec/requests/lalen/kit_assign_tests_spec.rb` — 8 examples
