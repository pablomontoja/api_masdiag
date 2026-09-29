---

description: "Task list for feature implementation"
---

# Tasks: Measurement-Scoped Result-Available Notifications

**Input**: Design documents from `/specs/014-measurement-scoped-result-notifications/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/service-interfaces.md, quickstart.md

**Tests**: Included and REQUIRED — constitution Principle III (Test-First, NON-NEGOTIABLE) mandates RSpec specs before implementation code for every layer touched.

**Organization**: Tasks are grouped by user story (US1, US2, US3 from spec.md) to enable independent implementation and testing of each.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

Single Rails project at repository root (`/home/pswider/rails/api_masdiag`). All paths below are relative to that root.

---

## Phase 1: Setup

No new project structure, dependencies, or tooling needed — this feature modifies existing files within the existing `Notifications::*`/`Toxo::*` subsystem. No Phase 1 tasks required.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The `Note` model change is the one true prerequisite — every user story's idempotency behavior (US1, US3) depends on `"result-available-email"` being a valid key for `subject_type: "Measurement"`. Nothing else is foundational; `EventDispatcher`/`Sender`/job/controller changes are story-specific work, not shared setup.

**⚠️ CRITICAL**: T001–T002 MUST complete before any User Story phase begins.

- [X] T001 [P] Write failing spec in `spec/models/note_spec.rb` (create if absent) asserting `"result-available-email"` is a valid `key` for a `Note` with `subject_type: "Measurement"` (e.g. `Note.new(subject: create(:measurement), key: "result-available-email").valid?` → true), and that the existing `subject_type: "Sample"` usage of the same key remains valid.
- [X] T002 Make T001 pass: in `app/models/note.rb`, add `"result-available-email"` to `KEYS_BY_SUBJECT["Measurement"]` (per data-model.md — do not remove it from `KEYS_BY_SUBJECT["Sample"]`, which the other five events and historical rows still need).

**Checkpoint**: `Note` supports per-measurement `"result-available-email"` tracking. User story implementation can now begin.

---

## Phase 3: User Story 1 - Contractor gets notified for every authorized measurement on a sample (Priority: P1) 🎯 MVP

**Goal**: Move the `:result_available` trigger and idempotency tracking from Sample-scoped to Measurement-scoped throughout `EventDispatcher`, `Sender`, `ResultAvailableJob`, and the controller/route, so every measurement's authorization independently triggers its own notification.

**Independent Test**: Create one sample with two measurements, both eligible under `CUTOFF_DATE`. Authorize/dispatch the first — one email + one `Note` (`subject_type: "Measurement"`). Authorize/dispatch the second — a *second*, distinct email + a *second* `Note`. Re-dispatching either measurement a second time sends no further email.

### Tests for User Story 1 (write first, confirm they FAIL)

- [X] T003 [P] [US1] In `spec/services/notifications/sender_spec.rb`, add/update examples: `Sender.call(event: :result_available, measurement:, mail:, recipient:, family: :toxo)` creates a `Note` with `subject: measurement` (not `subject: measurement.sample`); calling it twice for the *same* measurement sends only one email (idempotent); calling it once each for two *different* measurements on the *same* sample sends two emails and creates two distinct `Note` rows. Also confirm all five other events still pass via `sample:` only, unchanged.
- [X] T004 [P] [US1] In `spec/services/notifications/event_dispatcher_spec.rb`, add/update examples: `EventDispatcher.call(event: :result_available, measurement:)` resolves family via `measurement.sample` and (for `:toxo`) calls `Toxo::SampleNotificationMailer.result_available(sample, measurement)`; calling with `measurement:` for two different measurements on one sample results in two independent `Sender` dispatches (both send); calling `:result_available` without `measurement:` raises `ArgumentError`; calling any other event without `sample:` still raises `ArgumentError` (unchanged prior behavior — confirm no regression).
- [X] T005 [P] [US1] In `spec/jobs/notifications/result_available_job_spec.rb`, rewrite around `perform(measurement_id)`: a measurement with `AuthorizedAt >= CUTOFF_DATE` dispatches (`EventDispatcher.call(event: :result_available, measurement:)`); a measurement with `AuthorizedAt < CUTOFF_DATE` or `nil` does not dispatch; a missing `measurement_id` does nothing; retry-on-StandardError config present (`described_class.rescue_handlers.map(&:first)` includes `"StandardError"`); **new regression case**: two measurements on the *same* sample, both eligible, each dispatched via a separate `perform_now` call, both result in a sent email (was: second silently skipped).
- [X] T006 [P] [US1] In `spec/requests/masdiag/result_available_spec.rb`, rewrite around `POST /masdiag/result_available/:measurement_id`: enqueues `Notifications::ResultAvailableJob` with `measurement.Id`; returns 422 with `{"error" => "measurement not found"}` for an unknown id; `MasdiagCheck` institution gating unchanged (still requires `institution_id == 1` `ApiAccount`).

### Implementation for User Story 1

- [X] T007 [US1] In `app/services/notifications/sender.rb`: add `measurement:` optional keyword to `self.call`/`#initialize` alongside existing `sample:`; set `@subject = measurement || sample` and `@sample = measurement&.sample || sample`; change `already_sent?`/`mark_note` to use `@subject` (`subject_type: @subject.class.name, subject_id: @subject.id`) instead of hardcoded `"Sample"`/`@sample.Id`; in `record_audit`, set `event.measurement = @measurement` (was `nil`) — keep `event.sample = @sample` unchanged. (Depends on T003 failing correctly first.)
- [X] T008 [US1] In `app/services/notifications/event_dispatcher.rb`: add `measurement:` optional keyword to `self.call`/`#initialize`; derive `@sample = measurement&.sample || sample`; add `ArgumentError` guards (`:result_available` requires `measurement:`; every other event requires `sample:`); in `dispatch_toxo`, replace `Toxo::SampleNotificationMailer.public_send(@event, @sample)` with an explicit branch — `@event == :result_available ? Toxo::SampleNotificationMailer.result_available(@sample, @measurement) : Toxo::SampleNotificationMailer.public_send(@event, @sample)` — and pass `measurement: @measurement` into `Sender.call` for `:result_available` (other events keep passing `sample: @sample`). (Depends on T004, T007.)
- [X] T009 [US1] In `app/jobs/notifications/result_available_job.rb`: change `perform(sample_id)` → `perform(measurement_id)`, looking up `Measurement.find_by(Id: measurement_id)`; change `#eligible?` to `measurement.AuthorizedAt.present? && measurement.AuthorizedAt >= CUTOFF_DATE`; call `Notifications::EventDispatcher.call(event: :result_available, measurement: measurement)`. `CUTOFF_DATE` constant value unchanged. (Depends on T005, T008.)
- [X] T010 [US1] In `config/routes.rb`, change `post "result_available/:sample_id", to: "notifications#result_available"` to `post "result_available/:measurement_id", to: "notifications#result_available"` (inside the existing `namespace :masdiag` block).
- [X] T011 [US1] In `app/controllers/masdiag/notifications_controller.rb`: update the `result_available` action to look up `Measurement.find_by(Id: params[:measurement_id])`, render a 422 with `{"error" => "measurement not found"}` when absent, and enqueue `Notifications::ResultAvailableJob.perform_later(measurement.Id)`. First check whether `enqueue_by_id`/`render_sample_not_found` are used by any *other* action in this controller (`grep -n "enqueue_by_id\|render_sample_not_found" app/controllers/masdiag/notifications_controller.rb`) — if `result_available` is the only caller, adapt those helpers in place (renaming `render_sample_not_found` → `render_measurement_not_found`); if shared, add a small measurement-specific inline block instead of genericizing the shared helper. (Depends on T006, T009, T010.)

**Checkpoint**: User Story 1 fully functional and independently testable — run `bundle exec rspec spec/models/note_spec.rb spec/services/notifications/sender_spec.rb spec/services/notifications/event_dispatcher_spec.rb spec/jobs/notifications/result_available_job_spec.rb spec/requests/masdiag/result_available_spec.rb` green.

---

## Phase 4: User Story 2 - Each notification identifies which result it concerns (Priority: P2)

**Goal**: The Toxo `result_available` email keeps showing the full measurements table on every send, plus one new sentence naming the specific measurement/test that triggered this particular email.

**Independent Test**: Trigger the mailer directly with `(sample, measurement)` for a specific measurement on a multi-measurement sample; confirm the rendered email body contains a sentence naming that measurement's `project.Name`, in addition to the existing full table.

**Depends on**: Phase 3 (T008 passes `measurement:` into the mailer call — US2 extends that same call's arity).

### Tests for User Story 2 (write first, confirm they FAIL)

- [X] T012 [US2] In `spec/mailers/toxo/sample_notification_mailer_spec.rb`, update every `described_class.result_available(sample)` call site to `described_class.result_available(sample, measurement)` (passing the specific triggering measurement per example); add a new example asserting the rendered body includes a sentence containing the triggering measurement's `project.Name`; confirm existing full-table assertions (all measurements listed, PDF links, status labels, Polish locale forcing) still pass unmodified in content, just with the new required second argument.

### Implementation for User Story 2

- [X] T013 [US2] In `app/mailers/toxo/sample_notification_mailer.rb`: change `result_available(sample)` to `result_available(sample, measurement)`, adding `@triggering_measurement = measurement` inside the existing `I18n.with_locale(:pl)` block alongside `@sample`/`@portal_url`/`@measurements`. (Depends on T012.)
- [X] T014 [US2] In `app/views/mailers/toxo/sample_notification_mailer/result_available.html.erb`: add one sentence above the existing table using `@triggering_measurement.project.Name`, e.g. `<p>Niniejsza wiadomość dotyczy wyniku badania: <strong><%= @triggering_measurement.project.Name %></strong>.</p>`. Leave the `@measurements.each` table loop untouched. (Depends on T013.)

**Checkpoint**: User Stories 1 AND 2 both work independently — run `bundle exec rspec spec/mailers/toxo/sample_notification_mailer_spec.rb` green alongside Phase 3's suite.

---

## Phase 5: User Story 3 - Legacy (non-Toxo) notification path does not regress (Priority: P1)

**Goal**: Prevent the `:lab`-family `dispatch_lab` branch from resending already-delivered files now that its trigger can fire more than once per sample (a direct side effect of US1's per-measurement triggering).

**Independent Test**: For a lab-family sample with an `OnlineFile` already marked `is_notification_send: true`, trigger `:result_available` dispatch again (simulating a second measurement's trigger on the same sample) — confirm no new email is sent and no new `ResultSendingEvent` audit row is created for that already-sent file. For a sample with one delivered and one new file, confirm only the new file is included.

**Depends on**: Phase 3 (T008 — `EventDispatcher` must already accept `measurement:` before this guard can be exercised via the new per-measurement trigger path).

### Tests for User Story 3 (write first, confirm they FAIL)

- [X] T015 [US3] In `spec/services/notifications/event_dispatcher_spec.rb`, add examples for the `dispatch_lab`/`:result_available` branch: with a sample whose `OnlineFile`s are all `is_notification_send: true`, dispatching `:result_available` for any measurement on that sample sends no email and creates no new audit record; with a mix of already-sent and new `OnlineFile`s, dispatching includes only the unsent one(s) in the outgoing `ContractorResultNotificationMailer.send_mail` call.

### Implementation for User Story 3

- [X] T016 [US3] In `app/services/notifications/event_dispatcher.rb`, change the private `lab_result_file_ids` method to add `.where(is_notification_send: false)` to its existing `OnlineFile.joins(...).where(...)` scope; in `dispatch_lab`'s `:result_available` branch, skip (`return Sender::Result.new(status: :skipped)`) when `lab_result_file_ids` is empty, instead of unconditionally calling `MasdiagMailer::ContractorResultNotificationMailer.send_mail`. (Depends on T015.)

**Checkpoint**: All three user stories independently functional — run `bundle exec rspec spec/services/notifications/event_dispatcher_spec.rb` green alongside Phases 3–4's suites.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T017 [P] Run `bundle exec rspec spec/services/notifications/recipient_resolver_spec.rb spec/services/notifications/template_resolver_spec.rb spec/models/measurement_spec.rb` and confirm all pass unmodified (per plan.md's Constitution Check — these collaborators should need zero changes; a failure here means an assumption in research.md needs revisiting, not a silent spec patch).
- [X] T018 Run the full feature suite together: `bundle exec rspec spec/models/note_spec.rb spec/services/notifications spec/jobs/notifications spec/requests/masdiag/result_available_spec.rb spec/mailers/toxo/sample_notification_mailer_spec.rb` — full green run.
- [X] T019 Execute the quickstart.md manual verification scenario (two measurements on one sample, both eligible, dispatched sequentially) in a transactional/scratch context and confirm two distinct emails + two distinct `Note` rows — the direct regression test for the originally reported bug.
- [X] T020 Execute quickstart.md's legacy `:lab`-family regression check (dispatch twice for the same sample, second call sends nothing new) to confirm US3's guard holds end-to-end, not just at the unit level.
- [X] T021 Run `bundle exec rspec` for the full suite (not just this feature) to confirm no unrelated regression, per constitution Development Workflow item 3.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: None — skipped, no tasks.
- **Foundational (Phase 2)**: No dependencies — BLOCKS all user stories (T002 must land before any `Note`-creating spec in US1/US3 can pass).
- **User Story 1 (Phase 3)**: Depends on Phase 2. No dependency on US2/US3.
- **User Story 2 (Phase 4)**: Depends on Phase 2 and on Phase 3's T008 (the `EventDispatcher`→mailer call site this story extends).
- **User Story 3 (Phase 5)**: Depends on Phase 2 and on Phase 3's T008 (the per-measurement trigger path whose side effect this story guards against). Independent of Phase 4.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Parallel Opportunities

- T001 can run alone (Foundational has only one real task pair, T001→T002, inherently sequential RED→GREEN).
- Within Phase 3, T003–T006 (all spec files, all different files) can be written in parallel; T007–T011 are sequential (each depends on the prior file's change being in place, and T011 depends on T009+T010).
- Phase 4 and Phase 5 can proceed in parallel once Phase 3 (specifically T008) is complete — they touch entirely different files (`sample_notification_mailer.rb`/view vs. `event_dispatcher.rb`'s `dispatch_lab`/`lab_result_file_ids`).
- T017 in Phase 6 can run in parallel with T018–T020 (read-only verification, no shared file writes).

---

## Parallel Example: User Story 1 tests

```bash
# Launch all four US1 spec-writing tasks together (different files, no dependencies):
Task: "Add measurement:-keyword idempotency examples to spec/services/notifications/sender_spec.rb"
Task: "Add measurement:-keyword dispatch examples to spec/services/notifications/event_dispatcher_spec.rb"
Task: "Rewrite spec/jobs/notifications/result_available_job_spec.rb around perform(measurement_id)"
Task: "Rewrite spec/requests/masdiag/result_available_spec.rb around POST .../:measurement_id"
```

## Parallel Example: User Story 2 + User Story 3 (after Phase 3 completes)

```bash
# US2 (mailer/view) and US3 (dispatch_lab guard) touch disjoint files — run as two parallel tracks:
Track A (US2): T012 → T013 → T014
Track B (US3): T015 → T016
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001–T002).
2. Complete Phase 3: User Story 1 (T003–T011) — this alone fixes the originally reported bug (missed notifications for later measurements on a sample).
3. **STOP and VALIDATE**: Run Phase 3's checkpoint suite; execute quickstart.md's manual scenario.
4. This is deployable on its own — US2 (identifying sentence) and US3 (lab regression guard) are both real requirements from the spec, but US1 alone already delivers the core fix.

### Incremental Delivery

1. Foundational → Note supports Measurement-scoped tracking.
2. User Story 1 → contractors get every measurement's notification, not just the first (MVP, fixes the reported bug).
3. User Story 3 → lab-family contractors protected from the resend regression this fix would otherwise introduce (ship alongside or immediately after US1 — do not ship US1 alone to production without US3, since US1 alone introduces the lab-family regression described in research.md decision 5).
4. User Story 2 → emails gain the identifying sentence (pure UX polish, safe to ship last if needed).

### Recommended Grouping

Although the template separates these into independent phases, **US1 and US3 should ship together** — US3 exists specifically to prevent a regression that US1 introduces. US2 is the only story that is truly independently deferrable without introducing risk.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story (US1/US2/US3) for traceability back to spec.md.
- Every implementation task's paired test task MUST fail before the implementation task begins, per constitution Principle III.
- No task touches a file outside the list enumerated in plan.md's Project Structure section.
- Avoid: skipping the RED step, combining US1's `EventDispatcher`/`Sender` changes with US3's `dispatch_lab` guard in one commit (keep them separable per the story boundaries above, even though both land in `event_dispatcher.rb`).
