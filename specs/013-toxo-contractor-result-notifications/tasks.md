# Tasks: Toxo Contractor Result Notifications Repair

**Input**: Design documents from `/specs/013-toxo-contractor-result-notifications/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/service-interfaces.md, quickstart.md

**Tests**: Included and REQUIRED — constitution Principle III ("Test-First (NON-NEGOTIABLE)") mandates RSpec specs before implementation code for every service, job, mailer, and model method touched.

> **Post-implementation revision (2026-09-24)**: After all 20 tasks below were completed and verified, the user requested simplifying T002/T003/T008/T010/T011 — the `KeyValueDbStore`-backed cutoff-date accessor and the standalone `Notifications::ResultEligibility` service object were judged over-engineered for a value set once at deploy time. Both were removed: the cutoff is now `Notifications::ResultAvailableJob::CUTOFF_DATE`, a plain Ruby constant, checked via a private `#eligible?` method inline in the job. The files/specs created by T002, T003, T008, T010 were deleted; T009/T011 were updated in place. The task entries below are kept as the historical record of what was built, tested, and then simplified — they no longer describe the current state of the codebase. See spec.md's Clarifications, plan.md's Constitution Check, research.md's revision note, data-model.md, and contracts/service-interfaces.md for the corrected current-state description.

**Organization**: Tasks are grouped by user story (spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are exact per plan.md's Project Structure section

## Path Conventions

Single existing Rails app (`api_masdiag`). All paths are relative to the repository root, under the existing `app/` and `spec/` trees — no new top-level directories.

---

## Phase 1: Setup

**Purpose**: No new dependencies, gems, or project scaffolding are required — this feature extends existing Rails app structure only. Setup is limited to confirming the target environment is ready.

- [X] T001 Run `bundle exec rspec spec/services/notifications/ spec/jobs/notifications/ spec/mailers/toxo/ spec/models/key_value_db_store_spec.rb spec/models/measurement_spec.rb` to confirm the baseline suite is green before making any change

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared building blocks both P1 user stories (US1, US2) depend on — the cutoff-date storage mechanism and the reusable PDF-link method. Per data-model.md and research.md §2/§5, these are additive-only (no schema change) but are consumed by both stories below, so they must land first.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Write failing spec for `KeyValueDbStore.measurement_notification_cutoff_date` / `=` getter/setter pair in `spec/models/key_value_db_store_spec.rb` (covers: round-trips a `Date`, returns `nil` when unset per data-model.md's "no default seeded" note)
- [X] T003 [P] Implement `KeyValueDbStore.measurement_notification_cutoff_date` / `=` in `app/models/key_value_db_store.rb`, following the existing `metanephrine_settled_samples` getter/setter convention, key `"MeasurementNotificationCutoffDate"` (contracts/service-interfaces.md §5) — make T002 pass
- [X] T004 [P] Write failing spec for `Measurement#report_pdf_url` in `spec/models/measurement_spec.rb` (covers: returns the signed URL when `online_file.file_contents` present, returns `nil` when absent — mirror the existing controller-concern behavior in `app/controllers/concerns/toxo/measurement_serialization.rb#unencrypted_result_url`)
- [X] T005 [P] Implement `Measurement#report_pdf_url` in `app/models/measurement.rb`, reusing the `prepare_active_storage; url_for(...)` logic (research.md §5) — make T004 pass
- [X] T006 Update `app/controllers/concerns/toxo/measurement_serialization.rb#unencrypted_result_url` to delegate to the new `Measurement#report_pdf_url` instead of duplicating the logic, and re-run its existing controller/request specs to confirm no regression in the `toxo` JSON API's `report_pdf_url` field
- [X] T007 Verify `config.action_mailer.default_url_options` (host/protocol) is configured for every environment that will send this mailer (`config/environments/development.rb`, `staging.rb`, `production.rb`) per research.md §5's caveat that mailer-context `url_for` requires an explicit host; add the missing option(s) if absent — VERIFIED: `config/initializers/default_url_options.rb` already sets `Rails.application.routes.default_url_options[:host]` for every environment (dev/test/staging/production), which is what `Rails.application.routes.url_helpers.url_for` (used by `Measurement#report_pdf_url`) resolves against; no code change needed

**Checkpoint**: Cutoff-date storage and PDF-link generation are in place and independently tested — both P1 user stories can now proceed.

---

## Phase 3: User Story 1 - Only measurements authorized from the cutoff date onward can trigger a notification (Priority: P1) 🎯 MVP

**Goal**: A Toxo sample only becomes eligible to trigger a result-available notification if it has at least one measurement authorized on/after the configured cutoff date; the historical backlog is never swept up.

**Independent Test**: Seed samples with measurements authorized before/after a configured cutoff, invoke `Notifications::ResultAvailableJob.perform_now(sample.Id)` for each, and confirm only samples with a qualifying measurement generate an email (per quickstart.md).

### Tests for User Story 1

- [X] T008 [P] [US1] Write failing spec for `Notifications::ResultEligibility.call(sample:)` in `spec/services/notifications/result_eligibility_spec.rb` — cases: measurement authorized on/after cutoff → `true`; only measurement(s) before cutoff → `false`; no measurements → `false`; no cutoff configured → `false` (fail closed, per FR-002a)
- [X] T009 [US1] Extend `spec/jobs/notifications/result_available_job_spec.rb` with failing cases: ineligible sample → `Notifications::EventDispatcher` is NOT called, no email sent; eligible sample → dispatch proceeds as before (existing passing cases must remain green)

### Implementation for User Story 1

- [X] T010 [US1] Implement `Notifications::ResultEligibility` in `app/services/notifications/result_eligibility.rb` per contracts/service-interfaces.md §2 (input: `sample:`, output: boolean, queries `sample.measurements` against `KeyValueDbStore.measurement_notification_cutoff_date`) — make T008 pass
- [X] T011 [US1] Modify `app/jobs/notifications/result_available_job.rb#perform` to call `Notifications::ResultEligibility.call(sample:)` before `Notifications::EventDispatcher.call(...)` and return early (no dispatch) when ineligible, per contracts/service-interfaces.md §1 — make T009 pass

**Checkpoint**: User Story 1 is fully functional and independently testable — the cutoff gate now protects every result-available dispatch, with zero change to the legacy `send_all` path (FR-004) or to `:lab`-family/other events.

---

## Phase 4: User Story 2 - Result email lists every measurement on the sample (Priority: P1)

**Goal**: The `result_available` email shows a table of every measurement on the sample (name, status, authorization date, PDF link), not just a generic portal link.

**Independent Test**: Render the mailer for a sample with measurements in different states (authorized+PDF, authorized without PDF yet, not yet authorized) and confirm the table lists every one with the correct data per spec.md User Story 2's acceptance scenarios.

### Tests for User Story 2

- [X] T012 [P] [US2] Write failing spec (create if absent) in `spec/mailers/toxo/sample_notification_mailer_spec.rb` for `#result_available` — asserts `@measurements` is set to `sample.measurements`, and the rendered HTML body contains one row per measurement showing project name, status, authorization date (or blank when absent), and PDF link (or no link when absent) per contracts/service-interfaces.md §4's table. Include a dedicated multi-measurement scenario per SC-004: a sample with 3+ measurements where 2 have an available PDF and 1 does not — assert ALL measurements with an available PDF render a working link (not just that link rendering works in isolation for one row), and the one without a PDF renders no link.

### Implementation for User Story 2

- [X] T013 [US2] Modify `app/mailers/toxo/sample_notification_mailer.rb#result_available` to set `@measurements = sample.measurements` alongside the existing `@sample`/`@portal_url` — make T012's instance-variable assertions pass
- [X] T014 [US2] Update `app/views/mailers/toxo/sample_notification_mailer/result_available.html.erb` to render a table iterating `@measurements`, showing `measurement.project.Name` (Mobility-translated), `measurement.Status`, `measurement.AuthorizedAt` (blank if `nil`), and `measurement.report_pdf_url` as a link (omitted/placeholder if `nil`) — make T012's rendering assertions pass
- [X] T015 [P] [US2] Check `Toxo::MeasurementSerialization`/`Toxo::Constants` (and any other Toxo-facing code) for an existing human-readable status label map before introducing a new one; if found, reuse it in the view for the Status column per research.md §6 — otherwise render the raw integer as-is (no new stringly-typed constant) — VERIFIED: no existing status label map found (only `Toxo::Constants::PROJECT_NAMES`, which is for project names, not measurement status); rendered the raw `Status` integer as-is, consistent with what the `toxo` JSON API already exposes

**Checkpoint**: User Stories 1 AND 2 both work independently — a notified sample's email now shows the full measurement table, and only cutoff-eligible samples ever get notified.

---

## Phase 5: User Story 3 - Forward-going trigger reliably fires exactly once per sample (Priority: P2)

**Goal**: Confirm/guard that the existing per-sample trigger, now combined with the cutoff gate and the new table, still fires exactly one email per sample and never double-sends.

**Independent Test**: Authorize a new Toxo measurement (on/after cutoff) end-to-end, confirm exactly one email is sent, and confirm a repeated trigger invocation sends no second email.

### Tests for User Story 3

- [X] T016 [US3] Extend `spec/jobs/notifications/result_available_job_spec.rb` (or `spec/services/notifications/sender_spec.rb` if more appropriate) with a case: two sequential `Notifications::ResultAvailableJob.perform_now(sample.Id)` calls for the same eligible sample result in exactly one delivered email (idempotency, FR-008), confirming the cutoff/table changes did not disturb the existing `Note`-based one-shot guarantee

### Implementation for User Story 3

- [X] T017 [US3] No production code change expected — if T016 fails, investigate whether T010/T011's eligibility check interacts incorrectly with `Notifications::Sender#already_sent?` (e.g., ensure the eligibility check happens strictly before any `Note` is read/written) and fix in `app/jobs/notifications/result_available_job.rb` or `app/services/notifications/result_eligibility.rb` accordingly — VERIFIED: T016 passed on first run, no fix needed. The eligibility check runs entirely before `EventDispatcher`/`Sender` are invoked, so it never reads or writes a `Note`, leaving the existing one-shot guarantee undisturbed.

**Checkpoint**: All three user stories are independently functional; the full spec.md acceptance-scenario set passes.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification against the full spec and constitution gates.

- [X] T018 [P] Run `bundle exec rspec spec/services/notifications/ spec/jobs/notifications/ spec/mailers/toxo/ spec/models/key_value_db_store_spec.rb spec/models/measurement_spec.rb spec/controllers/toxo/ spec/requests` (or the project's equivalent full-suite command) to confirm no regressions anywhere touched, including the `toxo` namespace controller/request specs affected by T006 — RESULT: 218 examples, 0 failures (no `spec/controllers/toxo/` directory exists in this API-only app; used `spec/requests/toxo/` instead). NOTE: the default `:project` factory (`spec/factories/project_factory.rb`) hardcodes `Id: 2` without `find_or_create_by`, unlike `:toxo_project_igg`/`:toxo_project_igm`/etc. It collides with a `Mysql2::Error: Duplicate entry '2' for key 'PRIMARY'` whenever more than one measurement/project is created in the same example. All new specs in this feature work around it by passing an explicit `project: create(:project_without_fixed_id)`. This is a pre-existing factory fragility, not introduced by this feature — worth a follow-up fix (e.g. adding `find_or_create_by` to the default `:project` factory) but out of scope here.
- [X] T019 Walk through `quickstart.md` manually in a Rails console (development or test environment) to confirm the end-to-end behavior matches all documented verification steps, including the explicit "backlog is NOT recovered" and "legacy `send_all` path is unaffected" checks — VERIFIED via a scratch RSpec example (run once, then deleted, not committed to the suite): seeded a Toxo sample with pre-cutoff/post-cutoff/pending measurements + a PDF-bearing one, triggered `ResultAvailableJob` twice (1 email both times — idempotent), and triggered it again for a pre-cutoff-only sample (0 emails). Email body contained all three measurement names and the PDF link. `send_all`/`ContractorResultsNotifierJob` was not touched by any task, confirming the legacy path remains unaffected by construction.
- [X] T020 Re-verify constitution Constitution Check gates from plan.md still hold after implementation (controller action line counts, model file line counts, no new query object needed, no new directory added) — update plan.md's Constitution Check table only if a deviation was discovered and justified — VERIFIED, no deviations; plan.md updated with a post-implementation re-check note

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — run first.
- **Foundational (Phase 2)**: Depends on Setup. BLOCKS both Phase 3 (US1) and Phase 4 (US2), since both consume `KeyValueDbStore.measurement_notification_cutoff_date` (US1) and/or `Measurement#report_pdf_url` (US2).
- **User Story 1 (Phase 3)**: Depends on Foundational only. Independently testable and shippable as the MVP (the cutoff safety gate is the higher-risk, higher-priority half of the fix).
- **User Story 2 (Phase 4)**: Depends on Foundational only (specifically T005's `Measurement#report_pdf_url`). Does NOT depend on Phase 3 — the table renders correctly whether or not the eligibility gate exists, since eligibility only decides *whether* an email is sent, not *what* it contains. Can be implemented in parallel with Phase 3 by a second developer.
- **User Story 3 (Phase 5)**: Depends on BOTH Phase 3 and Phase 4 being complete, since it verifies the combined behavior (eligibility gate + table rendering) doesn't break the pre-existing idempotency guarantee.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Within Each User Story

- Tests written and failing before implementation (T008/T009 before T010/T011; T012 before T013/T014).
- Model/service layer before job/mailer layer that consumes it.
- Story complete (checkpoint) before moving to the next priority phase, if working sequentially.

### Parallel Opportunities

- T002–T005 (Foundational): the `KeyValueDbStore` pair (T002/T003) and the `Measurement#report_pdf_url` pair (T004/T005) touch different files and can run in parallel as two [P] tracks; T006/T007 depend on T005/T007 respectively and are not parallel with them.
- Phase 3 (US1) and Phase 4 (US2) can be worked in parallel by two developers once Phase 2 is complete — they touch disjoint files (`result_eligibility.rb`/`result_available_job.rb` vs. `sample_notification_mailer.rb`/`result_available.html.erb`).
- T015 (status label check) is parallelizable with T013/T014 since it's a research/verification step, not a blocking code change to the same file.

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch both foundational tracks together:
Task: "Write failing spec for KeyValueDbStore.measurement_notification_cutoff_date in spec/models/key_value_db_store_spec.rb, then implement in app/models/key_value_db_store.rb"
Task: "Write failing spec for Measurement#report_pdf_url in spec/models/measurement_spec.rb, then implement in app/models/measurement.rb"
```

## Parallel Example: Phase 3 + Phase 4

```bash
# Once Phase 2 is complete, two developers can proceed independently:
Task: "User Story 1 — eligibility gate: result_eligibility_spec.rb, result_eligibility.rb, result_available_job.rb"
Task: "User Story 2 — measurement table: sample_notification_mailer_spec.rb, sample_notification_mailer.rb, result_available.html.erb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL — blocks both P1 stories).
3. Complete Phase 3: User Story 1 (the cutoff safety gate).
4. **STOP and VALIDATE**: Confirm no notification ever fires for a pre-cutoff-only sample, and that the legacy `send_all` path is untouched.
5. This alone is deployable: it makes the (still table-less) `result_available` email safe against a backlog flood the moment the underlying per-sample trigger issue is separately resolved.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add User Story 1 → test independently → this is the MVP safety gate.
3. Add User Story 2 → test independently → the email becomes useful (full measurement table).
4. Add User Story 3 → test independently → confirms no regression in the one-shot guarantee.
5. Polish → full-suite regression pass + manual quickstart walkthrough.

### Parallel Team Strategy

With two developers: both complete Setup + Foundational together, then one takes Phase 3 (US1) while the other takes Phase 4 (US2) in parallel, converging on Phase 5 (US3) once both are done.

---

## Notes

- [P] tasks touch different files with no dependency on an incomplete task.
- [Story] labels map every user-story-phase task to spec.md's US1/US2/US3 for traceability.
- Tests are written first and must fail before their corresponding implementation task, per constitution Principle III.
- No task in this list touches `app/controllers/masdiag_mailer/emails_controller.rb`, `MasdiagMailer::ContractorResultsNotifierJob`, or any other legacy `send_all` file — per FR-004, that path is explicitly out of scope and untouched.
- No task implements backlog recovery/backfill — per the Clarifications session, this was explicitly rejected; do not add one.
