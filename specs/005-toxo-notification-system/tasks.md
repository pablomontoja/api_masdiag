---
description: "Task list for Toxo Sample Email Notification System (unified dispatch)"
---

# Tasks: Toxo Sample Email Notification System

**Input**: Design documents from `/specs/005-toxo-notification-system/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: REQUIRED. Constitution III (Test-First, NON-NEGOTIABLE) mandates RSpec specs written and failing before implementation, FactoryBot only, no fixtures.

**Organization**: Grouped by user story (from spec.md) in priority order. Shared dispatch infrastructure is in the Foundational phase because every event routes through it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US6 map to the spec user stories
- File paths are repo-relative to `/home/pswider/rails/api_masdiag`

## Story ↔ event map

| Story | Event | Priority | Toxo mailer action | Lab delegate (non-toxo) |
|-------|-------|----------|--------------------|-------------------------|
| US1 | result_available (F) | P1 | `#result_available` | `ContractorResultNotificationMailer` |
| US2 | sample_accepted (B) | P1 | `#sample_accepted` | `SendAcceptanceNotificationsMailer` |
| US3 | sample_rejected (E) | P1 | `#sample_rejected` | `SendCancellationNotificationsMailer` |
| US4 | registration_reminder (C) | P2 | `#registration_reminder` | none (new) |
| US5 | registration_reminder_final (D) | P2 | `#registration_reminder_final` | none (new) |
| US6 | order_confirmation (A) | P3 | `#order_confirmation` (+PDF) | `IndMailer`/`ThreeMethylDopaMailer` |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Constants, dependencies, and config the whole feature relies on.

- [X] T001 [P] Add `TOXO_INSTITUTION_IDS = [...]` constant (fill ids from the toxo pool config) beside `LALEN_INSTITUTION_IDS` in `app/lib/v1/common.rb`
- [X] T002 [P] Add the six notification keys (`order-confirmation-email`, `sample-accepted-email`, `registration-reminder-email`, `registration-reminder-final-email`, `sample-rejected-email`, `result-available-email`) to `Note#available_keys` in `app/models/note.rb`
- [X] T003 [P] Create `config/initializers/business_time.rb` configuring Polish public holidays (fixed + movable/Easter-based) into `BusinessTime::Config.holidays`
- [X] T004 [P] Spec for the `business_time` Polish-holiday config in `spec/initializers/business_time_spec.rb` (asserts a known weekend + a fixed holiday + one movable feast are non-business days)
- [X] T005 [P] Spec for `Note` new keys accepted / unknown key rejected in `spec/models/note_spec.rb`

**Checkpoint**: Constants, holiday calendar, and idempotency keys exist and are tested.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The unified dispatch layer every event routes through. **No user story can be implemented until this is complete.**

**⚠️ CRITICAL**: Blocks all of Phase 3+.

### Tests first (write and ensure they FAIL)

- [X] T006 [P] Spec `spec/services/notifications/template_resolver_spec.rb`: toxo-institution sample → `:toxo`; other institution → `:lab`; institution resolved via contractor for **registered** samples and via **code→RSC→institution for unregistered** samples; asserts that for an unregistered sample whose virtual patient's `ContractorId` points to a *different* institution than the code's RSC, the resolver uses the **RSC/code institution** (virtual `ContractorId` MUST NOT be used) — covers spec §Clarifications
- [X] T007 [P] Spec `spec/services/notifications/recipient_resolver_spec.rb`: registered event → contractor email (respects `are_notifications_enabled`); reminder event → `institution.email_for_notifications` via code→RSC→institution; **virtual patient `ContractorId` NOT used**; blank/disabled → returns skip reason
- [X] T008 [P] Spec `spec/services/notifications/sender_spec.rb`: delivers via given mailer; creates the `Note` (correct key + `[family]` in description); writes `ResultSendingEvent`/`Fileable`/`DbFile` audit; second call is a no-op (Note guard); missing recipient → skip without raising
- [X] T009 [P] Spec `spec/services/notifications/event_dispatcher_spec.rb`: given (event, sample) picks family via `TemplateResolver`, resolves recipient, routes to `Toxo::SampleNotificationMailer` for toxo vs existing lab mailer for non-toxo, delegates to `Sender`

### Implementation

- [X] T010 [US-shared] Create `Notifications::TemplateResolver` in `app/services/notifications/template_resolver.rb` (institution for a sample; `:toxo` if `institution.id.in?(V1::Common::TOXO_INSTITUTION_IDS)` else `:lab`) — depends on T001, T006
- [X] T011 [P] [US-shared] Create `Notifications::RecipientResolver` in `app/services/notifications/recipient_resolver.rb` (registered → contractor email; reminders → code→RSC→`institution.email_for_notifications`; never virtual `ContractorId`) — depends on T007
- [X] T012 [US-shared] Create `Notifications::Sender` in `app/services/notifications/sender.rb` (idempotency guard on `Note`; deliver mail; write `ResultSendingEvent`/`Fileable`/`DbFile` audit mirroring `SendAcceptanceNotificationsMailer#set_sendmail`; create `Note`) — depends on T002, T008
- [X] T013 [US-shared] Create `Notifications::EventDispatcher` in `app/services/notifications/event_dispatcher.rb` (orchestrates TemplateResolver → RecipientResolver → mailer selection → Sender; maps event → lab mailer for non-toxo delegation) — depends on T010, T011, T012, T009
- [X] T014 [P] [US-shared] Create the empty `Toxo::SampleNotificationMailer < ApplicationMailer` shell in `app/mailers/toxo/sample_notification_mailer.rb` with `default template_path => "mailers/#{self.name.underscore}"` (actions added per story) — depends on nothing beyond ApplicationMailer
- [X] T015 [P] [US-shared] Create `Masdiag::NotificationsController < ApplicationController` including `MasdiagCheck`, with a private `find_sample_by_id_or_code` helper and shared `enqueue_and_ok(job, arg)` returning `json_response("OK")` — in `app/controllers/masdiag/notifications_controller.rb`
- [X] T016 [US-shared] Create the toxo mailer layout/partials as needed under `app/views/mailers/toxo/sample_notification_mailer/` (shared header/footer partial, Polish, portal URL from `V1::Common`) — depends on T014

**Checkpoint**: Dispatch layer, mailer shell, controller shell, and routing helper exist and are green. User stories can now proceed in parallel.

---

## Phase 3: User Story 1 — Result available (Priority: P1) 🎯 MVP

**Goal**: When a report is published, the ordering party gets a "Wynik badania" email (toxo template for toxo institutions, existing lab template otherwise), exactly once, audited.

**Independent Test**: POST `/masdiag/result_available {sample_id}` for a toxo sample with a valid contractor email → one "Wynik badania" email + one Note + one audit record; re-POST → no second email.

### Tests first (write and ensure they FAIL)

- [X] T017 [P] [US1] Request spec `spec/requests/masdiag/result_available_spec.rb`: 200 + job enqueued for valid sample; 422 for unknown sample; `MasdiagCheck` blocks non-institution-1 caller
- [X] T018 [P] [US1] Job spec `spec/jobs/notifications/result_available_job_spec.rb`: delegates to `EventDispatcher` with `event: :result_available`; idempotent on retry; `retry_on StandardError … attempts: 5`
- [X] T019 [P] [US1] Mailer spec `spec/mailers/toxo/sample_notification_mailer_spec.rb` (result_available example): subject "Wynik badania", references sample number + portal URL, Polish body

### Implementation

- [X] T020 [US1] Add `#result_available(sample)` action to `Toxo::SampleNotificationMailer` + view `app/views/mailers/toxo/sample_notification_mailer/result_available.html.erb` (spec §F wording) — depends on T014, T016, T019
- [X] T021 [US1] Map `:result_available` → `MasdiagMailer::ContractorResultNotificationMailer` for the non-toxo family in `Notifications::EventDispatcher` — depends on T013
- [X] T022 [US1] Create `Notifications::ResultAvailableJob` in `app/jobs/notifications/result_available_job.rb` (`retry_on StandardError, wait: :exponentially_longer, attempts: 5`; calls `EventDispatcher`) — depends on T013, T018
- [X] T023 [US1] Add route `post "result_available", to: "notifications#result_available"` under `namespace :masdiag` in `config/routes.rb` and the controller action enqueuing `ResultAvailableJob` — depends on T015, T017

**Checkpoint**: US1 fully functional and independently testable (MVP).

---

## Phase 4: User Story 2 — Sample accepted (Priority: P1)

**Goal**: When a sample is qualified for testing, the ordering party gets a "Potwierdzenie przyjęcia próbki do badań" email, once, audited, with correct template family.

**Independent Test**: POST `/masdiag/sample_accepted {sample_id}` → one acceptance email (toxo vs lab by institution) + Note + audit; re-POST → no duplicate.

### Tests first (write and ensure they FAIL)

- [X] T024 [P] [US2] Request spec `spec/requests/masdiag/sample_accepted_spec.rb`: 200 + enqueue; 422 unknown; MasdiagCheck
- [X] T025 [P] [US2] Job spec `spec/jobs/notifications/sample_accepted_job_spec.rb`: dispatches `:sample_accepted`; idempotent; retry config
- [X] T026 [P] [US2] Mailer spec (sample_accepted example) in `spec/mailers/toxo/sample_notification_mailer_spec.rb`: subject "Potwierdzenie przyjęcia próbki do badań", references sample number

### Implementation

- [X] T027 [US2] Add `#sample_accepted(sample)` action + view `app/views/mailers/toxo/sample_notification_mailer/sample_accepted.html.erb` (spec §B) — depends on T014, T016, T026
- [X] T028 [US2] Map `:sample_accepted` → `MasdiagMailer::SendAcceptanceNotificationsMailer` (non-toxo family) in `EventDispatcher` — depends on T013
- [X] T029 [US2] Create `Notifications::SampleAcceptedJob` in `app/jobs/notifications/sample_accepted_job.rb` — depends on T013, T025
- [X] T030 [US2] Add route `post "sample_accepted"` + controller action in `config/routes.rb` / `Masdiag::NotificationsController` — depends on T015, T024

**Checkpoint**: US1 + US2 both independently functional.

---

## Phase 5: User Story 3 — Sample rejected (Priority: P1)

**Goal**: When a sample is disqualified, the ordering party gets an "Odrzucenie próbki zleconej do badań" email including the six sample-identification fields, once, audited.

**Independent Test**: POST `/masdiag/sample_rejected {sample_id}` → one rejection email containing sample code, number, client internal number (if present), material type, ordered tests, execution mode (CITO/Standard); re-POST → no duplicate.

### Tests first (write and ensure they FAIL)

- [X] T031 [P] [US3] Request spec `spec/requests/masdiag/sample_rejected_spec.rb`: 200 + enqueue; 422 unknown; MasdiagCheck
- [X] T032 [P] [US3] Job spec `spec/jobs/notifications/sample_rejected_job_spec.rb`: dispatches `:sample_rejected`; idempotent; retry config
- [X] T033 [P] [US3] Mailer spec (sample_rejected example): subject "Odrzucenie próbki zleconej do badań"; asserts all six detail fields present (incl. CITO/Standard from `execution_mode`, material type, ordered tests from measurements)

### Implementation

- [X] T034 [US3] Add `#sample_rejected(sample)` action + view `app/views/mailers/toxo/sample_notification_mailer/sample_rejected.html.erb` rendering the six detail fields (spec §E) — depends on T014, T016, T033
- [X] T035 [US3] Map `:sample_rejected` → `MasdiagMailer::SendCancellationNotificationsMailer` (non-toxo family) in `EventDispatcher` — depends on T013
- [X] T036 [US3] Create `Notifications::SampleRejectedJob` in `app/jobs/notifications/sample_rejected_job.rb` — depends on T013, T032
- [X] T037 [US3] Add route `post "sample_rejected"` + controller action — depends on T015, T031

**Checkpoint**: All three P1 stories (US1–US3) independently functional — core value delivered.

---

## Phase 6: User Story 4 — Registration reminder (Priority: P2)

**Goal**: A delivered-but-unregistered sample triggers a "Przypomnienie o konieczności rejestracji próbki" email to the institution notification address (new toxo template — no lab analog), once.

**Independent Test**: POST `/masdiag/registration_reminder {code}` for a delivered unregistered toxo code → one reminder email to `institution.email_for_notifications` referencing sample number + portal; re-POST → no duplicate.

### Tests first (write and ensure they FAIL)

- [X] T038 [P] [US4] Request spec `spec/requests/masdiag/registration_reminder_spec.rb`: accepts `{sample_id}` or `{code}`; 200 + enqueue; 422 when neither resolves; MasdiagCheck
- [X] T039 [P] [US4] Job spec `spec/jobs/notifications/registration_reminder_job_spec.rb`: resolves sample by id or code; dispatches `:registration_reminder`; recipient via code→RSC→institution; idempotent; retry config
- [X] T040 [P] [US4] Mailer spec (registration_reminder example): subject "Przypomnienie o konieczności rejestracji próbki"; references sample number + portal URL

### Implementation

- [X] T041 [US4] Add `#registration_reminder(sample)` action + view `app/views/mailers/toxo/sample_notification_mailer/registration_reminder.html.erb` (spec §C) — depends on T014, T016, T040
- [X] T042 [US4] In `EventDispatcher`, map `:registration_reminder` with no lab analog → for non-toxo institutions, skip-with-reason (only toxo family sends today) — depends on T013
- [X] T043 [US4] Create `Notifications::RegistrationReminderJob` in `app/jobs/notifications/registration_reminder_job.rb` (accepts sample id or code) — depends on T013, T039
- [X] T044 [US4] Add route `post "registration_reminder"` + controller action resolving id-or-code — depends on T015, T038

**Checkpoint**: US1–US4 independently functional.

---

## Phase 7: User Story 5 — Final registration reminder / recurring (Priority: P2)

**Goal**: A daily job finds delivered, still-unregistered toxo samples ≥7 business days past `AcceptanceDate` and sends the "Przypomnienie powtórne…" email (with return-at-client-expense warning), once each.

**Independent Test**: With a toxo sample delivered (AcceptanceDate set), patient virtual, 7 business days elapsed → running the sweep sends one final-reminder email; running again → none; a sample at 6 business days → none.

### Tests first (write and ensure they FAIL)

- [X] T045 [P] [US5] Service spec `spec/services/notifications/registration_reminders_finder_spec.rb`: selects delivered + virtual-patient + ≥7 business-days-since-AcceptanceDate + no final Note; excludes 6-business-day, registered, and already-noted samples; uses `business_time`
- [X] T046 [P] [US5] Job spec `spec/jobs/notifications/registration_reminder_final_job_spec.rb`: iterates finder results, dispatches `:registration_reminder_final`; idempotent across runs; retry config
- [X] T047 [P] [US5] Mailer spec (registration_reminder_final example): subject "Przypomnienie powtórne o konieczności rejestracji próbki"; includes the return-at-expense warning + portal URL

### Implementation

- [X] T048 [P] [US5] Create `Notifications::RegistrationRemindersFinder` in `app/services/notifications/registration_reminders_finder.rb` (delivered + virtual + `AcceptanceDate + 7.business_days <= Date.current` + no `registration-reminder-final-email` Note, scoped to `TOXO_INSTITUTION_IDS`) — depends on T001, T003, T045
- [X] T049 [US5] Add `#registration_reminder_final(sample)` action + view `app/views/mailers/toxo/sample_notification_mailer/registration_reminder_final.html.erb` (spec §D, with warning) — depends on T014, T016, T047
- [X] T050 [US5] Create `Notifications::RegistrationReminderFinalJob` in `app/jobs/notifications/registration_reminder_final_job.rb` (calls finder, dispatches per sample) — depends on T013, T048, T046
- [X] T051 [US5] Register the daily sweep in `config/recurring.yml` (e.g. `"0 6 * * *"`, queue `background`, class `Notifications::RegistrationReminderFinalJob`) — depends on T050

**Checkpoint**: US1–US5 functional; time-based reminder runs on schedule.

---

## Phase 8: User Story 6 — Order confirmation + PDF (Priority: P3)

**Goal**: On successful portal registration, the ordering party gets a "Potwierdzenie zlecenia badania" email with a PDF summary of the form, once.

**Independent Test**: Submit a valid toxo registration via `/toxo/samples/registrations` → one confirmation email with `potwierdzenie_zlecenia.pdf`; `422` registration → no email; re-submit same sample → no duplicate.

### Tests first (write and ensure they FAIL)

- [X] T052 [P] [US6] PDF spec `spec/pdfs/toxo/order_confirmation_pdf_spec.rb`: renders a PDF containing the submitted form fields for a sample
- [X] T053 [P] [US6] Job spec `spec/jobs/notifications/order_confirmation_job_spec.rb`: dispatches `:order_confirmation`; attaches PDF for toxo family; PDF failure caught + reported, does not raise out of the job; idempotent; retry config
- [X] T054 [P] [US6] Request spec `spec/requests/toxo/samples/registrations_order_confirmation_spec.rb`: successful create (valid Bearer session, Pundit `create?` allows) enqueues `SampleRegistrationConfirmationJob`; validation-failed create does NOT enqueue; **request with missing/invalid Bearer token → 401 and no enqueue; a session lacking `can_add_samples?` (Pundit `create?` denies) → 403/forbidden and no enqueue** — covers FR-020 for the portal touchpoint
- [X] T055 [P] [US6] Mailer spec (order_confirmation example): subject "Potwierdzenie zlecenia badania"; has PDF attachment

### Implementation

- [X] T056 [P] [US6] Create `Toxo::OrderConfirmationPdf < Prawn::Document` in `app/pdfs/toxo/order_confirmation_pdf.rb` summarizing the registration form (mirror `RegistrationConfirmationThreeOmdPdf`) — depends on T052
- [X] T057 [US6] Add `#order_confirmation(sample)` action + view `app/views/mailers/toxo/sample_notification_mailer/order_confirmation.html.erb`, attaching `Toxo::OrderConfirmationPdf` as `potwierdzenie_zlecenia.pdf` (spec §A) — depends on T014, T016, T056, T055
- [X] T058 [US6] Map `:order_confirmation` → `MasdiagMailer::IndMailer`/`ThreeMethylDopaMailer` for the non-toxo family in `EventDispatcher` — depends on T013
- [X] T059 [US6] Create `Notifications::SampleRegistrationConfirmationJob` in `app/jobs/notifications/sample_registration_confirmation_job.rb` (rescues PDF errors, reports via Sentry in production, does not fail registration) — depends on T013, T053
- [X] T060 [US6] Edit `Toxo::Samples::RegistrationsController#create` to enqueue `Notifications::SampleRegistrationConfirmationJob.perform_later(@sample.Id)` only when `@sample.errors.empty?` — depends on T059, T054

**Checkpoint**: All six user stories independently functional.

---

## Phase 9: Polish & Cross-Cutting

- [X] T061 [P] Run `bundle exec rspec` full suite green; fix any cross-story regressions
- [X] T062 [P] Verify no N+1 in `RegistrationRemindersFinder` and the dispatcher (use `.includes` on sample→patient→contractor / rsc→institution)
- [X] T063 [P] Run `quickstart.md` validation end-to-end (each event, template-selection-by-institution, idempotency, audit)
- [X] T064 Regression + scope-guard check: (a) non-toxo samples still route to existing lab mailers unchanged (B/E/F delegation); (b) assert the event catalog exposes **only** the six defined kinds — there is no dispatcher branch, `Note` key, or mailer action for sample return / archiving / disposal, so those physical-only procedures produce **no** email (FR-021). Optionally add to `spec/services/notifications/event_dispatcher_spec.rb` a test that `EventDispatcher` raises/no-ops for any event symbol outside the six kinds (e.g. `:sample_returned`, `:sample_disposed`) and never enqueues a mail
- [X] T065 [P] Add a brief note to `CLAUDE.md` (or the masdiag namespace docs) describing the unified `/masdiag/*` event endpoints and the dispatch layer

---

## Dependencies & Execution Order

### Phase dependencies
- **Setup (P1)**: no dependencies.
- **Foundational (P2)**: depends on Setup; **blocks all user stories**.
- **User Stories (P3–P8)**: each depends only on Foundational; independent of each other (all route through the shared dispatcher but touch different jobs/actions/views/routes).
- **Polish (P9)**: after desired stories complete.

### Critical path
T001–T005 → T006–T016 (dispatcher + mailer/controller shells) → then any story.

### Within a story
Tests (fail first) → mailer action+view → dispatcher lab-delegate mapping → job → route/controller action.

### Parallel opportunities
- Setup: T001–T005 all [P].
- Foundational tests T006–T009 all [P]; then T010–T016 partly parallel (T011, T014, T015 independent of T010/T012/T013).
- Once Foundational is done, US1–US6 can be built in parallel by different developers; each story's test tasks (e.g. T017–T019) are [P].
- Mailer actions across stories touch the same mailer file/views dir — sequence the `#action` additions within `sample_notification_mailer.rb` (T020, T027, T034, T041, T049, T057 not [P] against each other), but their views are separate files.

---

## Parallel Example: Foundational tests

```bash
# Launch the dispatch-layer specs together (all fail first):
Task: "spec/services/notifications/template_resolver_spec.rb"
Task: "spec/services/notifications/recipient_resolver_spec.rb"
Task: "spec/services/notifications/sender_spec.rb"
Task: "spec/services/notifications/event_dispatcher_spec.rb"
```

## Parallel Example: User Story 1

```bash
# Tests first, in parallel:
Task: "spec/requests/masdiag/result_available_spec.rb"
Task: "spec/jobs/notifications/result_available_job_spec.rb"
Task: "spec/mailers/toxo/sample_notification_mailer_spec.rb (result_available)"
```

---

## Implementation Strategy

### MVP (US1 only)
Setup → Foundational → US1 (result_available). Validate independently, demo. Delivers the highest-value notification through the full unified pipeline.

### Incremental delivery
Foundation → US1 → US2 → US3 (all P1 = complete acceptance/rejection/result set) → US4 → US5 (recurring) → US6 (confirmation + PDF). Each story is a shippable increment; non-toxo samples keep using existing lab mailers throughout.

### Notes
- Tests fail before implementation (constitution III); FactoryBot only, no fixtures.
- Jobs idempotent + `retry_on StandardError, wait: :exponentially_longer, attempts: 5`.
- Do not modify existing lab mailer internals — the dispatcher only *delegates* to them (memory: controller/mailer scope rule).
- Fill `TOXO_INSTITUTION_IDS` (T001) before the dispatcher can correctly route; until then, tests may stub the constant.
