# Feature Specification: Toxo Sample Email Notification System

**Feature Branch**: `005-toxo-notification-system`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "plik plans/003-notification-system.md zawiera informacje na temat tego jakie powiadomienia email mają być wysyłane w ramach akcji wykonywanych w namespace toxo ... przygotuj mailery oraz widoki; jeśli danego eventu nie da się obsłużyć za pomocą istniejących endpointów (toxo, masdiag, masdiag_mailer) to przygotuj odpowiednie endpointy ... niektóre eventy trzeba sprawdzać regularnie jako joby recurring."

## Clarifications

### Session 2026-07-17

- Q: For the registration reminders (C/D), a delivered sample is not yet registered, so no ordering party is attached through a registration — how is the recipient determined? → A: Resolve the recipient from the sample **code**: sample code → its reserved sample code → institution, using `institution.email_for_notifications`.
- Q: How does the system learn a sample was delivered but is still unregistered, and its delivery date? → A: A `Sample` record already exists at delivery — it is created when the lab accepts the sample, with `AcceptanceDate` as the delivery timestamp, and is linked to a placeholder patient with `IsVirtual == true` until the client registers it. "Delivered but unregistered" = a Sample with an `AcceptanceDate` whose patient is still virtual; the 7 working days are counted from `AcceptanceDate`.
- Q: Does the virtual patient's `ContractorId` resolve the reminder recipient? → A: No. The virtual patient's `ContractorId` MUST NOT be used to find the institution. The recipient for reminders is resolved strictly via the code → reserved sample code → institution path, using `institution.email_for_notifications`.
- Q: What backs the "at most one email per sample + kind" idempotency guarantee? → A: The existing `Note` model — a polymorphic marker with a per-`(subject_type, subject_id, key)` uniqueness constraint. Each notification kind is recorded as a `Note` on the Sample (subject) with a kind-specific `key`; presence of that Note means "already sent". The existing `ResultSendingEvent`/`Fileable` audit is still written for history continuity.
- Q: How is the 7-working-day deadline computed (weekends + Polish holidays)? → A: Use the `business_time` gem (already in the Gemfile, v0.13.0). Polish public holidays MUST be configured into `business_time` (including movable, Easter-based holidays) so that `AcceptanceDate` + 7 business days excludes weekends and holidays.

## Overview

The toxicology laboratory (Toxo) accepts client samples registered through the partner portal `toxo.masdiag.pl` and processed by the laboratory software **LabSample**. Throughout a sample's lifecycle — from order registration to result publication — the laboratory needs to keep the ordering party (Zleceniodawca / Partner) informed by email. Today no notification system exists for the Toxo workflow specifically; only generic diagnostic notifications exist for other lab flows.

This feature defines a Toxo-specific email notification system covering six distinct lifecycle events. Five events are triggered by a change in sample state (a client action in the portal, or a laboratory action in LabSample). One event is time-based and must be evaluated on a recurring schedule. LabSample and the partner portal will call laboratory API endpoints to signal state-triggered events; the recurring event is detected server-side without an external trigger.

Every notification must be sent **exactly once per sample per event kind**, and every send must be recorded in the laboratory's sent-notifications history so it is auditable alongside existing result-delivery records.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ordering party is notified when a result is available (Priority: P1)

When the laboratory publishes a test report for a Toxo sample, the ordering party responsible for that sample receives an email telling them the result is ready and directing them to the partner portal to retrieve the report.

**Why this priority**: Result delivery is the core value the laboratory provides to its partners. Missing or delayed result notifications directly block clients from acting on toxicology findings. If only one notification existed, this is the one that must.

**Independent Test**: Trigger the "result published" event for a sample whose ordering party has a notification email on file, and confirm a single "Wynik badania" email is delivered to that address, that it references the sample number, and that the send is recorded in history. Re-triggering the same event produces no duplicate email.

**Acceptance Scenarios**:

1. **Given** a Toxo sample with a published report and an ordering party that has a valid notification email, **When** the result-available event is triggered, **Then** exactly one email with subject "Wynik badania" is sent to that address, referencing the sample number and the portal URL, and the send is logged in the notifications history.
2. **Given** a sample whose result-available notification was already sent, **When** the event is triggered again, **Then** no additional email is sent.
3. **Given** a sample whose ordering party has no notification email on file, **When** the event is triggered, **Then** no email is sent and the reason is recorded/observable rather than raising an error.

---

### User Story 2 - Ordering party is notified when a sample is accepted for testing (Priority: P1)

When a sample arrives at the laboratory and is qualified for testing, the ordering party receives confirmation that the sample was accepted.

**Why this priority**: Acceptance confirmation closes the loop on physical sample delivery and is the first positive signal that testing has begun. It reduces "did you receive my sample?" support contacts and is a direct analogue of an existing acceptance notification in the diagnostic flow.

**Independent Test**: Trigger the "sample accepted" event for a delivered sample and confirm a single "Potwierdzenie przyjęcia próbki do badań" email referencing the sample number is delivered and logged, with no duplicate on re-trigger.

**Acceptance Scenarios**:

1. **Given** a delivered sample qualified for testing with an ordering party notification email on file, **When** the sample-accepted event is triggered, **Then** exactly one "Potwierdzenie przyjęcia próbki do badań" email referencing the sample number is sent and logged.
2. **Given** a sample whose acceptance notification was already sent, **When** the event is triggered again, **Then** no additional email is sent.

---

### User Story 3 - Ordering party is notified when a sample is rejected (Priority: P1)

When a sample arrives but is **not** qualified for testing (disqualified), the ordering party receives a rejection notification that includes the identifying details of the sample so they can reconcile it on their side.

**Why this priority**: A rejected sample requires client action (re-collection, re-shipment, clarification). The notification must carry enough sample detail for the client to identify which sample was rejected. Same criticality tier as acceptance — both are terminal decisions on physical intake.

**Independent Test**: Trigger the "sample rejected" event for a disqualified sample and confirm a single "Odrzucenie próbki zleconej do badań" email is delivered that lists the sample's identifying details, and that it is logged, with no duplicate on re-trigger.

**Acceptance Scenarios**:

1. **Given** a delivered but disqualified sample with an ordering party notification email on file, **When** the sample-rejected event is triggered, **Then** exactly one "Odrzucenie próbki zleconej do badań" email is sent, containing sample code, sample/package number, client internal number (if present), material type, ordered tests, and execution mode (CITO / Standard), and the send is logged.
2. **Given** a sample whose rejection notification was already sent, **When** the event is triggered again, **Then** no additional email is sent.

---

### User Story 4 - Ordering party is reminded to register a delivered sample (Priority: P2)

When a physical sample arrives at the laboratory but has no matching registration in the portal, the ordering party is reminded (first reminder) that they must register the sample before testing can be ordered.

**Why this priority**: Unregistered deliveries stall the workflow and eventually force a physical return at the client's expense. A first reminder recovers most of these before escalation, but the workflow can function without it (the sample is simply blocked), so it ranks below the terminal-decision notifications.

**Independent Test**: Trigger the "registration reminder" event for a delivered-but-unregistered sample and confirm a single "Przypomnienie o konieczności rejestracji próbki" email referencing the sample number and the portal is sent and logged, with no duplicate on re-trigger.

**Acceptance Scenarios**:

1. **Given** a delivered sample with no matching registration and an ordering party notification email on file, **When** the registration-reminder event is triggered, **Then** exactly one "Przypomnienie o konieczności rejestracji próbki" email referencing the sample number and the portal URL is sent and logged.
2. **Given** a sample whose first registration reminder was already sent, **When** the event is triggered again, **Then** no additional email is sent.

---

### User Story 5 - Ordering party receives a final registration reminder on a schedule (Priority: P2)

When 7 working days have elapsed since a sample was delivered and it is still not registered, the system automatically sends a stronger, final reminder warning that continued non-registration will result in the sample being returned at the client's expense. This event is not triggered by an external call — the system detects the elapsed deadline on a recurring schedule.

**Why this priority**: This is the escalation step that protects the laboratory from indefinitely holding unregistered samples. It depends on Story 4's delivery tracking and on a working-day calendar, so it is delivered after the first reminder.

**Independent Test**: With the clock advanced so that a delivered-but-unregistered sample has passed 7 working days since delivery, run the recurring evaluation and confirm a single "Przypomnienie powtórne o konieczności rejestracji próbki" email (including the return-at-client-expense warning) is sent and logged; running the evaluation again on the same sample sends no duplicate, and a sample only 6 working days past delivery is not notified.

**Acceptance Scenarios**:

1. **Given** a delivered, still-unregistered sample for which 7 working days (excluding weekends and holidays) have elapsed since delivery, **When** the recurring evaluation runs, **Then** exactly one "Przypomnienie powtórne o konieczności rejestracji próbki" email containing the return warning is sent and logged.
2. **Given** the same sample on a later run of the recurring evaluation, **When** it runs again, **Then** no additional final reminder is sent.
3. **Given** a delivered, unregistered sample only 6 working days past delivery, **When** the recurring evaluation runs, **Then** no final reminder is sent for it.
4. **Given** a sample that was registered before the 7-working-day deadline, **When** the recurring evaluation runs, **Then** no final reminder is sent for it.

---

### User Story 6 - Ordering party receives order confirmation with a PDF summary (Priority: P3)

When the ordering party completes and submits the sample registration form in the portal, they receive an order-confirmation email with a PDF attachment summarizing all data entered on the registration form.

**Why this priority**: Confirmation reassures the client that their order was received and gives them a record. It is valuable but the least blocking of the six events — registration already succeeds without it — and it carries an unresolved question about the exact email body wording, so it is sequenced last.

**Independent Test**: Submit a valid Toxo registration and confirm a single "Potwierdzenie zlecenia badania" email is delivered to the ordering party's notification address with a PDF attachment reproducing the submitted form data, and that the send is logged, with no duplicate on re-submission of the same registration.

**Acceptance Scenarios**:

1. **Given** a valid Toxo sample registration submitted through the portal by an ordering party with a notification email on file, **When** the registration is created, **Then** exactly one "Potwierdzenie zlecenia badania" email with a PDF summary attachment of the submitted form data is sent and logged.
2. **Given** a registration that failed validation, **When** submission is attempted, **Then** no confirmation email is sent.

---

### Edge Cases

- **Missing recipient email**: The ordering party has no notification address on file (or notifications are disabled for that account), or — for registration reminders — the sample's code cannot be resolved to a reserved sample code / institution, or the resolved institution has no `email_for_notifications`. The system must skip sending, record the skip reason, and never raise an error that would fail the triggering request or job.
- **Duplicate trigger / job retry**: A state-triggered endpoint is called twice, or a background job retries after a partial failure. The notification for that sample+event must not be sent more than once.
- **Event triggered out of order or in an invalid state**: An acceptance event is signaled for a sample that is not actually delivered, or a result-available event for a sample with no published report. The system must not send a misleading notification for a state that does not hold.
- **Working-day boundary**: The 7-working-day deadline must exclude weekends and recognized Polish public holidays; a sample delivered the day before a long weekend must not be counted as overdue prematurely.
- **Sample re-registration after a wrong registration**: A sample previously flagged as a wrong registration is later correctly registered. Confirmation and downstream notifications must reflect the corrected registration, not the wrong one.
- **Result re-publication / correction**: A report is re-issued for a sample that already received a result-available notification. By default this must not generate a second result email unless the workflow explicitly requires re-notification (see Assumptions).
- **PDF generation failure (order confirmation)**: If the PDF summary cannot be generated, the confirmation email handling must fail gracefully and be observable, without blocking the registration itself.

## Requirements *(mandatory)*

### Functional Requirements

#### Notification catalog

- **FR-001**: The system MUST support six notification kinds, each identified by a stable key: order confirmation (`order_confirmation`), sample accepted (`sample_accepted`), registration reminder (`registration_reminder`), final registration reminder (`registration_reminder_final`), sample rejected (`sample_rejected`), and result available (`result_available`).
- **FR-002**: Each notification MUST be addressed to the ordering party's designated notification email and MUST be composed in Polish. For events with a registration in the system (order confirmation, sample accepted, sample rejected, result available), the recipient is the ordering party's account notification address. For the registration reminders (registration reminder, final registration reminder), where the sample is not yet registered, the recipient MUST be resolved from the sample code: sample code → its reserved sample code → owning institution, using the institution's notification email (`institution.email_for_notifications`). For the reminders, the placeholder (virtual) patient's `ContractorId` MUST NOT be used to resolve the institution or recipient.
- **FR-003**: `order_confirmation` MUST include a PDF attachment summarizing all data submitted on the sample registration form, and use the subject "Potwierdzenie zlecenia badania".
- **FR-004**: `sample_accepted` MUST reference the sample number and use the subject "Potwierdzenie przyjęcia próbki do badań".
- **FR-005**: `registration_reminder` MUST reference the sample number and the partner portal URL (`toxo.masdiag.pl`) and use the subject "Przypomnienie o konieczności rejestracji próbki".
- **FR-006**: `registration_reminder_final` MUST reference the sample number and the partner portal URL, MUST include a warning that failure to register within the stated deadline results in the sample being returned at the ordering party's expense, and use the subject "Przypomnienie powtórne o konieczności rejestracji próbki".
- **FR-007**: `sample_rejected` MUST use the subject "Odrzucenie próbki zleconej do badań" and MUST include the sample's identifying details: sample code, sample/package number, client internal number (when present), material type, ordered tests, and execution mode (CITO / Standard).
- **FR-008**: `result_available` MUST reference the sample number and direct the recipient to the partner portal to retrieve the report, using the subject "Wynik badania".

#### Triggering

- **FR-009**: The system MUST send `order_confirmation` in response to a successful sample registration submitted through the portal registration flow.
- **FR-010**: The system MUST provide a way for the laboratory software (LabSample) and/or the portal to signal the state-triggered events — sample accepted, registration reminder, and sample rejected — for a specific sample, so that the corresponding notification is scheduled.
- **FR-011**: The system MUST send `result_available` when a test report is published/made available for a Toxo sample.
- **FR-012**: The system MUST detect the `registration_reminder_final` condition — a delivered sample still unregistered after 7 working days from delivery — on a recurring schedule, without requiring an external trigger, and send the notification for each qualifying sample. "Delivered but unregistered" is a Sample that has an `AcceptanceDate` (set when the lab accepts the sample) and whose associated patient is still a virtual placeholder (`IsVirtual == true`); the 7 working days are counted from `AcceptanceDate`.
- **FR-013**: Triggering endpoints exposed to LabSample and the portal MUST reside only within the `toxo`, `masdiag`, or `masdiag_mailer` API namespaces. New endpoints MUST be added only where an existing endpoint in those namespaces cannot already carry the event.
- **FR-014**: Triggering endpoints MUST identify the target sample unambiguously (e.g., by sample identifier or sample code) and MUST reject requests that do not identify an existing sample.
- **FR-015**: Sending MUST be performed asynchronously (via background processing) so that the triggering request or registration is not blocked by email delivery.

#### Idempotency, auditing, and eligibility

- **FR-016**: The system MUST ensure that each sample receives at most one email of a given notification kind, even under duplicate triggers, concurrent triggers, or background-job retries. Idempotency MUST be enforced using the existing `Note` model: each notification kind is recorded as a `Note` whose subject is the Sample and whose `key` identifies the kind; the `Note` uniqueness constraint on `(subject_type, subject_id, key)` guarantees at most one send per sample + kind. The kind-specific keys MUST be added to the `Note` model's allowed keys.
- **FR-017**: The system MUST record every notification that is sent — kind, sample, recipient address, timestamp, and a stored representation of the message — in the laboratory's sent-notifications history (`ResultSendingEvent`/`Fileable`), consistent with how existing result-delivery notifications are recorded. This audit record is written in addition to the idempotency `Note`.
- **FR-018**: When a notification cannot be sent because the recipient address is missing or notifications are disabled for the account, the system MUST skip the send without error and make the skip observable.
- **FR-019**: The recurring evaluation for `registration_reminder_final` MUST count elapsed time in working days, excluding weekends and recognized Polish public holidays, measured from the sample's `AcceptanceDate`. The computation MUST use the `business_time` gem, with Polish public holidays (fixed and movable/Easter-based) configured into it.
- **FR-020**: Access to the triggering endpoints MUST be restricted to the appropriate authenticated caller for each namespace (the laboratory/internal caller for `masdiag`/`masdiag_mailer`; the authenticated partner context for `toxo`), consistent with the existing authorization model of each namespace.

#### Scope guards

- **FR-021**: The system MUST NOT send any email for physical-only procedures that are explicitly out of scope: sample return (protokół odesłania), post-testing archiving, disposal, or return handling.
- **FR-022**: The notification system MUST apply only to samples belonging to the Toxo workflow and MUST NOT alter notification behavior of other laboratory flows (diagnostic, foreign, Lalen, etc.).

### Key Entities *(include if feature involves data)*

- **Sample (Toxo)**: A toxicology sample identified by a code and number. A Sample record exists from the moment the lab accepts the physical sample (`AcceptanceDate` set), initially linked to a virtual placeholder patient; it becomes fully registered when the client submits the registration form, at which point it is linked to the real ordering party. Moves through lifecycle states: delivered (accepted, patient virtual) → registered → qualified/rejected → in-testing → result-available. Carries the attributes surfaced in notifications: sample code, sample/package number, client internal number, material type, ordered tests (projects), execution mode (Standard / CITO), `AcceptanceDate` (delivery date), registration date, and wrong-registration flags.
- **Patient (virtual vs. real)**: Each Sample belongs to a patient. Before client registration the patient is a virtual placeholder (`IsVirtual == true`) carrying the owning `ContractorId`; after registration the Sample is linked to the real registered patient/ordering party. The virtual flag is the discriminator for "delivered but unregistered".
- **Ordering Party (Zleceniodawca / Partner / Contractor)**: The client account responsible for a registered sample. Holds the notification recipient email and a flag for whether notifications are enabled. Belongs to an institution.
- **Institution**: The partner organization owning a pool of reserved sample codes. Holds an institution-level notification email (`email_for_notifications`) used as the reminder recipient for delivered-but-unregistered samples, resolved via the sample's reserved sample code.
- **Reserved Sample Code**: A pre-assigned barcode belonging to an institution's pool before any registration exists. Provides the link from a physical sample code to its owning institution, enabling recipient resolution for registration reminders when no ordering-party registration is present yet.
- **Notification Event**: One of the six defined kinds (A–F), each mapping to a lifecycle transition (state-triggered) or an elapsed-deadline condition (time-triggered).
- **Notification Marker (`Note`)**: The polymorphic `Note` record whose subject is the Sample and whose `key` identifies the notification kind. Its `(subject_type, subject_id, key)` uniqueness constraint is the enforcement point for idempotency (at most one per sample + kind). Kind-specific keys are added to the Note model's allowed-keys list.
- **Sent-Notification Audit (`ResultSendingEvent`/`Fileable`)**: The existing history record capturing that a message was sent for a sample — recipient, timestamp, and stored message representation — written for history/reporting continuity alongside the idempotency marker.
- **Working-Day Calendar**: Working days (excluding weekends and recognized Polish public holidays) used to compute the 7-working-day deadline for the final reminder, provided by the `business_time` gem configured with the Polish holiday set.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For every sample that reaches a notification-eligible state and has a valid recipient, the corresponding notification is delivered — 100% coverage of eligible events, with zero eligible events silently dropped.
- **SC-002**: No sample ever receives more than one email of the same notification kind, across duplicate triggers, retries, and concurrent runs (0 duplicate notifications observed in acceptance testing).
- **SC-003**: 100% of sent notifications appear in the sent-notifications history with the correct kind, sample, recipient, and timestamp.
- **SC-004**: State-triggered notifications are queued for delivery within seconds of the triggering action, and the triggering request completes without waiting for email delivery.
- **SC-005**: The final registration reminder is sent to every qualifying sample no later than the first scheduled recurring run after the 7-working-day deadline passes, and is never sent before the deadline.
- **SC-006**: The rejection notification contains all six required sample-identification fields for 100% of rejection emails where the underlying data is present.
- **SC-007**: No emails are generated for out-of-scope physical procedures (return, archiving, disposal) — 0 such emails.

## Assumptions

- **Recipient**: The notification recipient is the ordering party's account email (the person responsible for registration). Where an account has notifications disabled or no email, the send is skipped rather than redirected.
- **Order-confirmation wording (Event A)**: The exact body text of the order-confirmation email is not fixed by the source document; the placeholder Polish text from the source plan is used as a starting point and treated as adjustable, while the mandatory element — a PDF attachment reproducing the submitted form — is fixed.
- **Result re-publication**: By default, a sample receives the `result_available` notification only once; re-publishing or correcting a report does not re-notify unless a future requirement explicitly asks for it.
- **Working days / holidays**: The `business_time` gem (already present) provides working-day arithmetic; Polish public holidays (fixed + movable) are configured into it. The deadline is 7 working days from `AcceptanceDate` for the final reminder.
- **Delivery tracking**: A Sample record already exists at delivery time (created on lab acceptance, `AcceptanceDate` set), linked to a virtual placeholder patient until registration. "Delivered but unregistered" and the elapsed working-day count are therefore evaluable from existing data (`AcceptanceDate` + patient `IsVirtual`) without introducing a new state model.
- **Existing infrastructure reuse**: The feature reuses the laboratory's existing mechanisms rather than introducing parallel ones — the `Note` model for idempotency markers, the `ResultSendingEvent`/`Fileable` history for audit, and the asynchronous email-delivery/recurring-job approach used by comparable notifications.
- **Trigger source**: LabSample (and, for order confirmation, the portal registration flow) is responsible for calling the state-triggered endpoints at the correct lifecycle moments; the specification defines the endpoints and guarantees, not LabSample's internal logic.
- **Namespaces**: All externally callable triggers live in `toxo`, `masdiag`, or `masdiag_mailer`; the recurring final-reminder evaluation runs server-side and needs no external endpoint.

## Dependencies

- Existing authentication/authorization for the `toxo`, `masdiag`, and `masdiag_mailer` namespaces.
- The existing sent-notifications history/audit mechanism used by current result-delivery notifications.
- The existing asynchronous (background job / recurring schedule) infrastructure.
- The `business_time` gem (already in the Gemfile) with Polish public holidays configured, for the 7-working-day computation.
- The ability to generate a PDF summary of a submitted registration form for the order-confirmation attachment.
