# Feature Specification: Toxo Contractor Result Notifications Repair

**Feature Branch**: `013-toxo-contractor-result-notifications`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "metoda send_all w app/controllers/masdiag_mailer/emails_controller.rb jest obecnie pewnego rodzaju wyzwalaczem do wysyłania wiadomości email jednak dla wyników Toxo wiadomości do Contractors się nie wysyłają przez ContractorResultsNotifierJob, trochę się pogubiłem, bo nie wiem czy to kwestia are_notifications_enabled czy problem jest gdzie indziej - mógłbym oczywiście siłowo dodać ResultAvailableJob do send_all, ale mogłoby to spowodować podwójne wysyłanie maili; dodatkowo ponieważ powiadomienia o wyniku Toxo nie działają od jakiegoś czasu to po naprawie tej sytuacji wolałbym, żeby brane były tylko pod uwagę Measurement autoryzowane od pewnej daty; ponadto jeden Sample może mieć wiele pomiarów więc wiadomość result_available.html.erb powinna zawierać tabelę listą pomiarów (Project.Name, Measurement.Status, Measurement.AuthorizedAt, link to PDF)"

## Clarifications

### Session 2026-09-24

- Q: Should the result-available email's measurement table list every measurement on the sample regardless of status, or only measurements that are authorized/result-available? → A: Table shows all measurements on the sample regardless of status (pending ones included).
- Q: Should missed historical (backlog) Toxo result notifications be actively recovered/backfilled once the fix ships? → A: No — the backlog MUST be ignored entirely. Contractors already had access to results via the Toxo portal website during the outage and did not rely on real-time email alerts, so nothing is lost by not backfilling. The cutoff date exists to draw a line so that old, pre-cutoff measurements never trigger a notification once the fix is live — not to recover them.
- Q: How should the email's PDF link be generated? → A: Reuse the same signed Active Storage URL (`report_pdf_url`, built via `url_for(measurement.online_file.unencrypted_result)`) that the Toxo portal's `/results` page already renders as a direct `<a href>` today — this is the existing, proven pattern, requires no new proxy/auth work, and needs no Toxo portal session to open.

### Session 2026-09-24 (post-implementation revision)

- Q: Is a dedicated `Notifications::ResultEligibility` service object plus `KeyValueDbStore`-backed runtime configurability the right level of ceremony for the cutoff date? → A: No — the user judged this over-engineered for a value that is expected to be set once, at implementation time, as part of shipping this fix, not adjusted routinely afterward. The cutoff is now a plain Ruby constant, `Notifications::ResultAvailableJob::CUTOFF_DATE`, checked inline in the job (no separate service object). This revises FR-002 (previously "MUST be configurable without a code change") and removes the `KeyValueDbStore.measurement_notification_cutoff_date` accessor and the fail-closed FR-002a requirement, since a constant can never be "unconfigured."
- Q: The email showed the test/project name in English instead of Polish, and the measurement status as a raw integer — what's the fix? → A: The project name issue was caused by `Project#Name` (Mobility) reading `I18n.locale`, which defaults to `:en` app-wide; `Toxo::SampleNotificationMailer#result_available` did not set a locale at all. Since no i18n infrastructure exists yet for this mailer to select a language based on `Contractor#locale`, the mailer now forces Polish via `I18n.with_locale(:pl) { ... }` around the whole method (this is a stopgap — per-contractor locale selection is out of scope for this fix and flagged as a TODO in the code). The status column now renders a Polish text label (`Toxo::SampleNotificationMailer::MEASUREMENT_STATUS_LABELS`), kept in sync with `Measurement::STATUS`/`enums.measurement_status` in the separate `toxo` frontend app, falling back to the raw integer for any status code outside 1–7.

## Background (as-is investigation)

Two independent, non-communicating notification mechanisms exist today:

1. **Legacy bulk path**: `POST /masdiag_mailer/send_all_mails` → `MasdiagMailer::EmailsController#send_all` → `MasdiagMailer::ContractorResultsNotifierJob`. This job selects contractors via `Contractor.where(are_notifications_enabled: true)` (a flag that defaults to `false` and has no relationship to Toxo) and finds unsent `OnlineFile` rows via a separate `is_notification_send` bookkeeping flag. It has no awareness of Toxo institutions and skips any contractor that has an `api_account`.
2. **New per-event path**: LabSample is expected to call `POST /masdiag/result_available` per sample → `Notifications::ResultAvailableJob` → `Notifications::EventDispatcher`, which resolves the sample's institution and picks the `:toxo` family (via `V1::Common::TOXO_INSTITUTION_IDS`) or the `:lab` family. For `:toxo`, it sends via `Toxo::SampleNotificationMailer#result_available`, gated on `Contractor#allow_result_notifications` (defaults `true`), with idempotency enforced by a one-shot `Note` record keyed `(subject: Sample, key: "result-available-email")` — a Sample can only ever receive this email once under the current mechanism.

Toxo contractors receive result emails **only** through path 2. That path does not run automatically or in bulk — it fires only when the per-sample `/masdiag/result_available` endpoint is actually called. If that call is missing, skipped, or the sample fails to resolve to a Toxo institution, no email is ever sent. This explains why Toxo result notifications have been silently broken for some period: it is a missing/unreliable-trigger problem, not a flag-configuration problem (`are_notifications_enabled` belongs to the unrelated legacy path), and not something the legacy `send_all` bulk path was ever wired to cover.

Wiring `Notifications::ResultAvailableJob` directly into `send_all` (as the user considered) is explicitly rejected as an approach here, because `send_all` has no per-sample scoping and could cause duplicate sends. Per clarification, the fix also does **not** attempt to recover or backfill the historical backlog of missed notifications — contractors retained access to results via the Toxo portal throughout, so nothing was lost, and mass-sending a backlog of old notifications risks flooding contractors and harming the notification's perceived value. Instead, the fix scopes the (repaired) forward-going trigger to only ever consider measurements authorized on or after a configurable cutoff date, so old, already-missed measurements are permanently and deliberately excluded rather than retroactively notified.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Only measurements authorized from the cutoff date onward can trigger a notification (Priority: P1)

As a Masdiag operator, I want the result-available notification to only ever consider measurements authorized on or after a configurable cutoff date, so that once the underlying trigger issue is fixed, old measurements that were already missed during the outage do not suddenly generate a wave of backlog emails to contractors who no longer expect or need them.

**Why this priority**: This is the safety boundary the user explicitly asked for before any other change ships — without it, fixing the trigger risks an unwanted mass-notification event the moment the fix is deployed (e.g., if a fixed trigger is later paired with any process that re-scans old samples).

**Independent Test**: Can be fully tested by seeding Toxo samples with measurements authorized before and after a configured cutoff date and confirming that only samples with a qualifying (on/after cutoff) authorized measurement are eligible to generate a result-available email; samples with only pre-cutoff authorized measurements never generate one, regardless of when the trigger runs.

**Acceptance Scenarios**:

1. **Given** a Toxo sample with a measurement authorized on or after the configured cutoff date, **When** the result-available trigger fires for that sample, **Then** the contractor is eligible to receive a result-available email (subject to existing recipient/idempotency rules).
2. **Given** a Toxo sample whose only authorized measurement(s) were authorized before the configured cutoff date, **When** the result-available trigger fires for that sample (e.g., a delayed/retried call), **Then** no email is sent for that sample.
3. **Given** the historical backlog of Toxo samples that were never notified before the fix shipped, **When** the fix is deployed, **Then** the system takes no automatic action to notify them — the backlog is intentionally left as-is, not backfilled.

---

### User Story 2 - Result email lists every measurement on the sample (Priority: P1)

As a Toxo contractor receiving a result-available email, I want to see, for the sample referenced in the email, a table listing every measurement (test) performed on that sample — its test name, its status, its authorization date/time (when authorized), and a link to its PDF report (when available) — instead of only a generic link to the portal, so I can see the full picture of the sample's tests and act on ready results directly from the email.

**Why this priority**: The user explicitly requested this because a single Sample can carry multiple Measurements (tests), and the current email gives no indication of which results are ready or where to find them individually. This is core to making the notification useful, not just delivered.

**Independent Test**: Can be fully tested by rendering the `result_available` email for a sample with multiple measurements in different states (some authorized with a PDF, some authorized without a PDF yet, some not yet authorized) and confirming the table lists every one of them with the correct project name, status, authorization timestamp (or its absence), and PDF link (or its absence).

**Acceptance Scenarios**:

1. **Given** a sample with three measurements, all authorized and each with a generated PDF report, **When** the result-available email is generated, **Then** the email body contains a table with one row per measurement, showing the test/project name, the measurement status, the authorization date/time, and a link to that measurement's PDF report.
2. **Given** a sample with a measurement that is authorized but has no PDF report available yet, **When** the result-available email is generated, **Then** that measurement still appears in the table with its name/status/date, but without a broken or misleading PDF link.
3. **Given** a sample with a measurement that has not yet been authorized (no `AuthorizedAt`), **When** the result-available email is generated, **Then** that measurement still appears in the table showing its name and current status, with no authorization date and no PDF link.
4. **Given** a sample where a test's display name has a translated (non-Polish) variant, **When** the recipient's locale calls for that translation, **Then** the table shows the translated name consistent with how the name is presented elsewhere in Toxo-facing content.
5. **Given** a measurement that has a PDF report available, **When** the email table renders that measurement's PDF link, **Then** the link points to the same signed report URL the Toxo portal's results page already uses for that measurement (no separate/alternate link mechanism).

---

### User Story 3 - Forward-going trigger reliably fires exactly once per sample (Priority: P2)

As a Masdiag operator, once User Story 1's cutoff safeguard is in place, I want newly authorized Toxo results to reliably trigger exactly one result-available email per sample through the existing per-event mechanism, so the notification stays healthy going forward without manual intervention.

**Why this priority**: Lower priority than the other P1 items because the forward-going single-event trigger already exists and is architecturally sound (per the investigation) — this story is about confirming/guarding it, not building it from scratch. It matters so the fix doesn't regress to the same silent-failure state.

**Independent Test**: Can be tested by authorizing a new Toxo measurement (on/after the cutoff date) end-to-end and confirming exactly one email is sent and the idempotency record prevents any further duplicate if the trigger fires again.

**Acceptance Scenarios**:

1. **Given** a Toxo sample with a newly authorized measurement (on/after the cutoff date) and no prior notification record, **When** the existing per-sample result-available trigger fires, **Then** exactly one email is sent containing the up-to-date measurement table.
2. **Given** a Toxo sample that has already been notified, **When** the per-sample trigger fires again for any reason (retry, duplicate call), **Then** no second email is sent.

---

### Edge Cases

- A sample has no measurements at all yet (e.g., trigger fired prematurely) — the system should not send an empty/misleading email; behavior should match existing "nothing to report" handling for this trigger.
- A sample belongs to a Toxo institution but its contractor record is missing or not resolvable — email cannot be sent; this should be handled the same way the existing per-event path already handles unresolved recipients (skip, not error).
- A sample's measurements include one authorized before the cutoff and another authorized on/after it — per User Story 1, the sample is still eligible (at least one qualifying measurement is enough to trigger), and per User Story 2 the email table shows *all* of the sample's measurements regardless of cutoff, since the cutoff governs only whether the sample is eligible to trigger a notification, not which of its measurements appear in the table.
- A measurement's PDF report is added to `OnlineFile` *after* the notification email has already been sent for that sample — since notification is one-shot per sample, this measurement's PDF link will never reach the contractor via email; this is accepted as existing one-shot behavior, not something this feature re-opens (see Assumptions).
- The historical backlog (samples never notified before this fix) must not be swept up by any part of this fix, now or via a future accidental re-run of the trigger against old data — the cutoff date is the sole, permanent safeguard against this.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST only consider a Toxo sample eligible to trigger a result-available notification if it has at least one measurement with `AuthorizedAt` on or after a cutoff date.
- **FR-002**: The cutoff date (FR-001) is defined as a constant in application code (`Notifications::ResultAvailableJob::CUTOFF_DATE`), set once at implementation time; changing it requires a code change and deploy. *(Revised 2026-09-24 — see Clarifications: the user judged a per-deploy code constant sufficient, since the cutoff is expected to be set once as part of shipping this fix, not adjusted routinely by operators.)*
- **FR-003**: The system MUST NOT take any automatic action to notify contractors about samples that were authorized, or whose notification was missed, entirely before the configured cutoff date — the historical backlog is explicitly out of scope and MUST NOT be backfilled.
- **FR-004**: The system MUST NOT alter or merge the legacy `send_all` / `ContractorResultsNotifierJob` bulk path with the Toxo per-event notification path; the two remain functionally separate.
- **FR-005**: The result-available email MUST include, for the sample being reported, a table listing every measurement on that sample (regardless of individual measurement status), with at minimum: the test/project name, the measurement's status, the measurement's authorization date/time (when present), and a link to that measurement's PDF report (when available). The test/project name and status MUST render in Polish; per FR-002's revision, no per-contractor locale selection exists yet, so Polish is forced for the entire email rather than left to the application's default locale (`:en`), which was producing incorrect output.
- **FR-006**: The PDF report link shown in the email table MUST be the same signed report URL already used by the Toxo portal's results page for that measurement — no new or alternate link/proxy mechanism.
- **FR-007**: When a listed measurement has no PDF report available at the time the email is generated (e.g., not yet authorized, or authorized but report not yet generated), the table MUST still show that measurement's name/status/authorization date (if any), without presenting a non-functional or misleading link.
- **FR-008**: The existing one-email-per-sample idempotency guarantee MUST be preserved: a sample that has already been notified MUST NOT receive a second result-available email, regardless of subsequently authorized measurements or newly available PDF reports.
- **FR-009**: The existing per-sample trigger MUST continue to respect contractor notification preferences (e.g., a contractor who has opted out of result notifications MUST NOT receive an email).

### Key Entities *(include if feature involves data)*

- **Sample**: A submitted specimen; may have many Measurements; is the unit of recipient/idempotency/eligibility (cutoff) scoping for result-available notifications.
- **Measurement**: A single test performed on a Sample, tied to a Project (test type); carries a workflow `Status` and, when authorized, an `AuthorizedAt` timestamp; may have an associated PDF report. Every measurement on the sample (not only authorized ones) is shown in the email table.
- **Project**: The test type/definition; provides the display name (translatable) shown per measurement row in the email.
- **Contractor**: The recipient organization for a sample's notifications; has per-event opt-in/opt-out preferences including result notifications.
- **Notification record (idempotency marker)**: The existing record that marks a sample as having already received its result-available email; unchanged by this feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero result-available emails are ever sent for a Toxo sample whose only authorized measurements are all dated before the configured cutoff, verified across normal operation after the fix ships.
- **SC-002**: The historical backlog of previously-missed Toxo notifications does not generate any emails as a direct result of this fix being deployed.
- **SC-003**: Zero contractors receive more than one result-available email for the same sample, verified across ordinary day-to-day per-sample notifications following the fix.
- **SC-004**: A contractor opening a result-available email can identify, without leaving the email, the status of every test on the sample and can reach each ready test's PDF report in one click, for 100% of measurements that have a report available at send time.
- **SC-005**: After the fix, newly authorized Toxo results (on/after the cutoff date) continue to generate exactly one notification per sample with no manual operator intervention, sustained over normal operation.

## Assumptions

- The cutoff date (FR-001, FR-002) is a single global constant applied uniformly to all Toxo samples/institutions, not configured per-institution or per-contractor, consistent with how the user described "measurements authorized from a certain date" as one shared line in time. Per the post-implementation revision, it is set once in code at deploy time rather than read from runtime-adjustable storage — there is no "unconfigured" state to fail closed against, since the constant always has a value.
- The email table intentionally includes every measurement on the sample, including ones not yet authorized and without a PDF, per the clarification that the table should reflect the sample's full test picture rather than only completed ones. Rows for not-yet-authorized measurements simply omit the authorization date and PDF link.
- The idempotency guarantee ("one email per sample, ever") from the existing mechanism is preserved as-is and is not modified by this feature; a sample notified once will not receive a follow-up email even if additional measurements are later authorized or additional PDF reports become available. This is accepted, pre-existing behavior, not something this feature changes.
- The PDF link in the email reuses the same signed Active Storage URL (`report_pdf_url`) the Toxo portal's results page already renders directly, with the same security/session characteristics (a bearer-style signed link, not requiring an active Toxo portal session to open) — this feature does not introduce a new access-control mechanism for that link.
- Out of scope: changes to the legacy `send_all` / `ContractorResultsNotifierJob` path, changes to non-Toxo (`:lab` family) result notifications, any backfill/recovery of the historical notification backlog, and changes to how a sample resolves to being "Toxo" (the existing institution-based resolution is assumed correct and unchanged).
