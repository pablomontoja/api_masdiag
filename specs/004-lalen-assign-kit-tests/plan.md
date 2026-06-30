# Implementation Plan: Lalen Assign Kit Tests

**Branch**: `004-lalen-assign-kit-tests` | **Date**: 2026-06-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-lalen-assign-kit-tests/spec.md`

## Summary

Add `LalenApi::AssignKitTestsJob`, a background job that — after a successful local test assignment to a `ReservedSampleCode` — calls the external Lalen portal API endpoint `POST /kit_tests` with the sample barcode and the list of assigned test `api_key` slugs. The job follows the identical pattern of the existing `LalenApi::RegisterKitJob`: uses the singleton `LalenApi::Client` connection, validates its arguments before sending, raises `LalenApi::Error` on non-success responses, retries with exponential backoff (10 attempts), and captures every failure to Sentry.

A companion value object `LalenApi::KitTests` (mirroring `LalenApi::RegisterKit`) carries the payload and encapsulates validation. The job is enqueued from `Lalen::KitController#assign_tests` after the local assignment transaction commits.

## Technical Context

**Language/Version**: Ruby 3.1.2, Rails 7

**Primary Dependencies**: Faraday (HTTP via `LalenApi::Client`), ActiveJob / Solid Queue, ActiveModel (for payload value object), Sentry

**Storage**: PostgreSQL — reads `ReservedSampleCode`, `ReservedTest`, `Project` (for `eng_name` → `api_key` mapping)

**Testing**: RSpec, FactoryBot, `ActiveJob::TestHelper`, WebMock (for Faraday stubs)

**Target Platform**: Linux server (production), same environment as existing jobs

**Project Type**: API-only Rails service (background job component)

**Performance Goals**: Job execution < 5 seconds under normal network conditions; retries handle transient failures

**Constraints**: Must not block the HTTP response — 201 is returned to the Lalen partner before the job runs; job failure must never roll back the local assignment

**Scale/Scope**: One job enqueued per successful test assignment; low volume (Lalen partner operations)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Rails Conventions | ✅ PASS | Job placed in `app/jobs/lalen_api/`, value object in `app/models/lalen_api/`, mirrors existing naming conventions |
| II. Service-Object Architecture | ✅ PASS | Assignment business logic extracted to `LalenApi::AssignKitTestsService`; controller is thin (≤15 lines); job owns async processing only |
| III. Test-First | ✅ PASS | RSpec job spec required before implementation; FactoryBot factories for `ReservedSampleCode`/`ReservedTest` to be used |
| IV. Security & Secrets | ✅ PASS | Lalen API credentials remain in Rails credentials (`lalenportalapi`); no secrets in source |
| V. Multi-Tenancy | ✅ PASS | Job receives barcode scoped to Lalen institution IDs; does not perform cross-tenant queries |
| VI. Layered Architecture | ✅ PASS | New code goes in Job layer (`app/jobs/`) and Model layer for value object (`app/models/`); no premature abstraction |

No constitution violations. Complexity Tracking table not required.

## Project Structure

### Documentation (this feature)

```text
specs/004-lalen-assign-kit-tests/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code

```text
app/
├── jobs/
│   └── lalen_api/
│       ├── register_kit_job.rb        # existing — reference pattern
│       └── assign_kit_tests_job.rb    # NEW
├── models/
│   └── lalen_api/
│       ├── register_kit.rb            # existing — reference pattern
│       ├── error.rb                   # existing — reused
│       └── kit_tests.rb              # NEW — payload value object
├── services/
│   └── lalen_api/
│       └── assign_kit_tests_service.rb  # NEW — business logic, constitution Principle II
└── controllers/
    └── lalen/
        └── kit_controller.rb          # MODIFIED — thin action delegates to service

spec/
├── jobs/
│   └── lalen_api/
│       └── assign_kit_tests_job_spec.rb     # NEW
├── models/
│   └── lalen_api/
│       └── kit_tests_spec.rb               # NEW
└── services/
    └── lalen_api/
        └── assign_kit_tests_service_spec.rb # NEW
```

**Structure Decision**: Single-project Rails app. New files follow exact namespace and directory conventions of the existing `LalenApi` integration (`app/jobs/lalen_api/`, `app/models/lalen_api/`).
