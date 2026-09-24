# Implementation Plan: Toxo Contractor Result Notifications Repair

**Branch**: `013-toxo-contractor-result-notifications` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-toxo-contractor-result-notifications/spec.md`

## Summary

Toxo contractors currently receive result-available emails only through the per-sample `Notifications::EventDispatcher` pipeline (triggered by LabSample calling `POST /masdiag/result_available`), which has no relationship to the legacy `are_notifications_enabled` flag the user suspected. This plan adds two narrowly-scoped changes to that existing pipeline, without touching the unrelated legacy `send_all`/`ContractorResultsNotifierJob` path:

1. A cutoff date — `Notifications::ResultAvailableJob::CUTOFF_DATE`, a plain Ruby constant checked inline in the job (revised 2026-09-24; originally planned as `KeyValueDbStore`-backed runtime config via a separate `Notifications::ResultEligibility` service, simplified after the user judged that level of configurability unnecessary for a value set once at deploy time) — gates whether a sample is eligible to trigger a result-available notification at all, so that, per explicit clarification, the historical backlog of missed notifications is never backfilled or swept up, only forward-going measurements authorized on/after the cutoff can trigger a notification.
2. `Toxo::SampleNotificationMailer#result_available` and its view gain a per-measurement table (test name, status, authorization date, PDF link) listing every measurement on the sample, with the PDF link reusing the exact same signed Active Storage URL mechanism the Toxo portal's own results page already uses.

## Technical Context

**Language/Version**: Ruby 3.4.10

**Primary Dependencies**: Rails 8.0.5 (API-only), Solid Queue (background jobs), Action Mailer, Alba (serialization — not used by this feature directly), Mobility (`Project#Name` translation), `business_time` (unrelated to this feature)

**Storage**: MySQL (via `mysql2`); this feature adds no new tables/columns — reuses `Measurements`, `Samples`, `Projects`, `Contractors`, `Notes`, `OnlineFile`. The cutoff date does not use storage at all — it is a Ruby constant (`Notifications::ResultAvailableJob::CUTOFF_DATE`), not a `config_entries`/`KeyValueDbStore` row.

**Testing**: RSpec + FactoryBot (no fixtures), per constitution Principle III — request/job/service/mailer specs as applicable

**Target Platform**: Linux server (existing production/staging Rails deployment)

**Project Type**: Single Rails API-only application (existing `api_masdiag`) — no frontend/mobile component in this repo; the separate `toxo` frontend app is referenced read-only for consistency (PDF link pattern) but is not modified by this feature

**Performance Goals**: N/A beyond existing per-sample async job processing (Solid Queue) — no batch/bulk operation is introduced (backlog recovery explicitly out of scope)

**Constraints**: MUST NOT alter the legacy `send_all`/`ContractorResultsNotifierJob` path (FR-004); MUST NOT re-open the existing one-shot-per-sample idempotency guarantee (FR-008); MUST NOT introduce a new PDF access/proxy mechanism (FR-006)

**Scale/Scope**: Single event type (`result_available`) within the existing `:toxo` family; six Toxo institutions (`V1::Common::TOXO_INSTITUTION_IDS`); no schema migration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design below.*

| Principle | Check | Status |
|---|---|---|
| I. Rails Conventions | New code follows existing `Notifications::` job/mailer namespace conventions exactly; no new namespace introduced. | PASS |
| II. Service-Object Architecture | Eligibility check is a one-line inline query in `Notifications::ResultAvailableJob` (revised: no separate service object — the user judged a full `Notifications::ResultEligibility` service unwarranted ceremony for this check, see Clarifications 2026-09-24); mailer stays composition-only; no business logic added to controllers. | PASS — see note below |
| III. Test-First | Specs written before implementation for the job's new branch and mailer/view output, per research.md §7. | PASS |
| IV. Security & Secrets | No new secrets; cutoff date is a plain code constant, not runtime config, so no config-storage concern applies. PDF link reuses existing signed-URL mechanism — no new access-control surface introduced. | PASS |
| V. Multi-Tenancy Integrity | Eligibility/table changes operate strictly within the already-institution-scoped `:toxo` dispatch path (`TemplateResolver` unchanged); no cross-tenant query introduced — the eligibility check queries only `sample.measurements`, already scoped to the one sample. | PASS |
| VI. Layered Architecture | Eligibility logic → private method on the job (not a controller/model; not promoted to a service object per the user's explicit simplification request — a single-line `WHERE` check on the job's own input does not cross the "complex business logic" threshold that would mandate a service object). Measurement list → simple association read (`sample.measurements`), not a query object (below the 3+-join threshold). PDF link logic → `Measurement#report_pdf_url` model method (simple derived attribute from an association the model already owns), avoiding duplication between the existing controller concern and the new mailer usage. | PASS |

**Abstraction threshold check**: No controller action grows past 15 lines (none touched). No model file approaches 300 lines from a 2-line addition (`Measurement#report_pdf_url`). No 3+-table-join query introduced (eligibility check is a single-table `WHERE` against `Measurements`). No premature query/presenter object introduced for the simple table rendering.

**Result**: No violations. Complexity Tracking table below is empty/not needed.

**Post-implementation re-check (2026-09-24, revised after user feedback)**: The user requested simplifying the eligibility mechanism after the initial implementation: removed the standalone `Notifications::ResultEligibility` service object (folded into a private method on `Notifications::ResultAvailableJob`) and removed the `KeyValueDbStore`-backed runtime configuration (replaced with a plain `CUTOFF_DATE` constant on the job). `Measurement` model grew from 48 to 55 lines (well under 300; unaffected by this revision — `#report_pdf_url` stays). No controller action was modified (the `toxo` controller concern only *shrank*, from 34 to 27 lines). No new directories were introduced. Full touched-area regression suite after the revision: 149+ examples, 0 failures. All six principles remain PASS under the simplified design.

## Project Structure

### Documentation (this feature)

```text
specs/013-toxo-contractor-result-notifications/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
├── contracts/
│   └── service-interfaces.md
└── tasks.md              # Phase 2 output (/speckit-tasks — not created by this command)
```

### Source Code (repository root)

This is a single existing Rails application (`api_masdiag`); no new top-level structure is introduced. Changed/new files live entirely within the existing `app/` tree:

```text
app/
├── jobs/
│   └── notifications/
│       └── result_available_job.rb          # MODIFIED — CUTOFF_DATE constant + inline eligibility check before dispatch
├── mailers/
│   └── toxo/
│       └── sample_notification_mailer.rb     # MODIFIED — result_available gains @measurements
├── models/
│   ├── key_value_db_store.rb                 # UNCHANGED (revised: the cutoff-date accessor pair was added then removed)
│   └── measurement.rb                        # MODIFIED — new #report_pdf_url method
└── views/
    └── mailers/
        └── toxo/
            └── sample_notification_mailer/
                └── result_available.html.erb # MODIFIED — add measurement table

spec/
├── jobs/
│   └── notifications/
│       └── result_available_job_spec.rb      # MODIFIED — cover eligibility branch against CUTOFF_DATE
├── mailers/
│   └── toxo/
│       └── sample_notification_mailer_spec.rb # MODIFIED — cover @measurements/table rendering
└── models/
    └── measurement_spec.rb                   # MODIFIED — cover #report_pdf_url
```

Note: `app/services/notifications/result_eligibility.rb` and `spec/services/notifications/result_eligibility_spec.rb` were created during initial implementation and then deleted after the user's simplification request (2026-09-24) — the eligibility check now lives inline in the job. `spec/models/key_value_db_store_spec.rb` was likewise created then deleted along with the removed getter/setter pair.

**Structure Decision**: Single-project Rails app structure (existing repository layout) — no new directories are introduced (constitution: "New directories MUST NOT be added without a constitution amendment"). All new code fits into the existing `app/services/notifications/`, `app/jobs/notifications/`, `app/models/`, and `app/mailers/toxo/` locations already established by this feature's precursor work (see CLAUDE.md's "Toxo notification dispatch" architecture description).

## Complexity Tracking

*No Constitution Check violations — table intentionally empty.*
