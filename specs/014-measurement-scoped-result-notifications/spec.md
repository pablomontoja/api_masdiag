# Feature Specification: Measurement-Scoped Result-Available Notifications

**Feature Branch**: `014-measurement-scoped-result-notifications`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "wydaje mi się, że podjęto błedne założenia projektowe odnośnie Notifications::EventDispatcher.call(event: :result_available) ; event :result_available jest charakterystyczny dla modelu Measurement; Sample has_many :measurements więc po pierwszym mailu kolejny już się nie wyśle; według mnie evant :result_available powinien być obsługiwany dla Measurement nie dla Sample w Notifications::EventDispatcher, Masdiag::NotificationsController#result_available jak i wszędzie indziej tam gdzie ma to związek; LabSample jeszcze nie używa NotificationsController#result_available więc to dobry czas na naprawę sytuacji"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Contractor gets notified for every authorized measurement on a sample (Priority: P1)

A Toxo contractor orders a sample that includes several distinct measurements
(e.g. IgG and IgM on the same sample). The lab authorizes each measurement's
result on a different day. The contractor must receive a result-available email
after *each* measurement is authorized, not just the first one.

**Why this priority**: This is the core defect being fixed. Today, once the
first measurement on a sample triggers the notification, every later
measurement on that same sample is silently never notified — contractors miss
results they are entitled to know about.

**Independent Test**: Create a sample with two measurements. Authorize the
first; confirm one email is sent. Authorize the second (on a later date);
confirm a *second*, distinct email is sent, and both are recorded as
independent notification events.

**Acceptance Scenarios**:

1. **Given** a sample with two measurements, both eligible under the existing
   authorization-date cutoff, **When** the first measurement is authorized and
   its notification is triggered, **Then** the contractor receives an email
   listing the full current state of all measurements on the sample.
2. **Given** the same sample, **When** the second measurement is later
   authorized and its notification is triggered, **Then** the contractor
   receives a *second* email (not silently skipped), again listing the full
   current state of all measurements on the sample.
3. **Given** a measurement's notification has already been sent once,
   **When** the same measurement's trigger fires again (e.g. retried job),
   **Then** no duplicate email is sent for that specific measurement.

---

### User Story 2 - Each notification identifies which result it concerns (Priority: P2)

Because the email always shows the full table of all measurements on the
sample, a contractor receiving several emails for the same sample over time
needs a quick way to tell which specific result triggered this particular
email, without having to diff tables by eye.

**Why this priority**: Directly improves the usability of the fix in User
Story 1 — without it, multiple emails for the same sample look
near-identical and confusing.

**Independent Test**: Trigger a notification for one specific measurement on
a multi-measurement sample; confirm the email contains a short, clearly
worded statement identifying that measurement (by its test/project name),
in addition to the full table.

**Acceptance Scenarios**:

1. **Given** a measurement's notification fires, **When** the email is
   rendered, **Then** it contains one clear sentence naming the test/project
   that this specific email concerns, in addition to the existing full table
   of all measurements on the sample.

---

### User Story 3 - Legacy (non-Toxo) notification path does not regress (Priority: P1)

Non-Toxo ("lab family") contractors already receive result notifications
through a separate, older mechanism that tracks "already notified" per file,
not per sample. That mechanism currently is only ever invoked once per
sample. Once notification triggering becomes per-measurement, this older
path must not start re-sending files that were already delivered.

**Why this priority**: Without this, fixing User Story 1 for Toxo
contractors would introduce duplicate-email/duplicate-audit-record
regressions for lab-family contractors — an unacceptable side effect of an
unrelated fix.

**Independent Test**: For a lab-family sample with multiple measurements,
trigger notification once per measurement as each is authorized. Confirm the
contractor is not sent previously-delivered files again, and no duplicate
audit records are created for files already marked as sent.

**Acceptance Scenarios**:

1. **Given** a lab-family sample where one measurement's result was already
   delivered to the contractor, **When** a second measurement on the same
   sample later becomes eligible for notification, **Then** only the newly
   available file is included in the outgoing notification — the
   already-delivered file is not resent.
2. **Given** a lab-family sample where every measurement's file has already
   been delivered, **When** another (already-notified) trigger fires for
   that sample, **Then** no new notification is sent at all.

---

### Edge Cases

- What happens when a notification trigger fires for a measurement that
  doesn't meet the existing authorization-date eligibility rule? → No
  notification is sent (unchanged from current behavior, now evaluated per
  measurement instead of per sample).
- What happens when two measurements on the same sample become eligible for
  notification at nearly the same time (concurrent processing)? → Each
  measurement is tracked as an independent notification event, so both may
  be processed and both may send successfully without interfering with each
  other.
- What happens to notification history recorded before this fix (when
  tracking was per-sample)? → It remains as historical record; no
  retroactive backfill or reprocessing of past samples is performed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST track "has this result-available notification
  been sent" per individual measurement, not per sample, so that authorizing
  additional measurements on an already-notified sample still triggers new
  notifications.
- **FR-002**: The system MUST NOT send more than one result-available
  notification for the same individual measurement.
- **FR-003**: When a result-available notification is sent, it MUST continue
  to present the complete, current list of all measurements on the sample
  (test name, status, authorization date, report link where available) —
  unchanged from existing behavior.
- **FR-004**: Every result-available notification MUST additionally state,
  in plain language, which specific measurement/test triggered that
  particular notification.
- **FR-005**: The existing authorization-date eligibility cutoff MUST
  continue to apply, now evaluated against the individual measurement's own
  authorization date rather than "any measurement on the sample."
- **FR-006**: The endpoint/trigger that reports a result as available MUST
  identify the specific measurement whose result became available, not just
  the sample it belongs to.
- **FR-007**: The legacy (non-Toxo) notification path MUST only include
  files/results not already delivered to the contractor in any outgoing
  notification, regardless of how many times its trigger fires for a given
  sample.
- **FR-008**: The legacy (non-Toxo) notification path MUST send no
  notification at all when there is nothing new to report for a sample.
- **FR-009**: All other result-lifecycle notification types (order
  confirmation, sample accepted, sample rejected, registration reminders)
  are unaffected by this change and MUST continue to be tracked and sent at
  the sample level, as today.

### Key Entities

- **Measurement**: An individual test performed as part of a sample; has an
  authorization date/timestamp and a status. A sample may have several
  measurements. This feature makes "was a result-available notification sent"
  a property of the measurement, not the sample it belongs to.
- **Sample**: A submitted specimen that may contain multiple measurements.
  Continues to be the unit that owns the recipient/contractor relationship
  and the full-table notification content.
- **Notification record**: The record used to prevent sending the same
  notification twice. Its subject changes from "the sample" to "the specific
  measurement" for this notification type only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A contractor with a multi-measurement sample receives one
  distinct result-available email per measurement as each becomes eligible,
  100% of the time (previously: only the first ever arrived).
- **SC-002**: No measurement ever causes more than one result-available
  email to be sent for itself, even under retry or concurrent-processing
  conditions.
- **SC-003**: Every result-available email a contractor receives clearly
  states, in one readable sentence, which test/measurement prompted it.
- **SC-004**: Lab-family (non-Toxo) contractors see zero duplicate
  deliveries or duplicate audit records after this change, verified against
  a sample with multiple measurements authorized at different times.
- **SC-005**: All other notification types (order confirmation, sample
  accepted/rejected, registration reminders) show no behavior change,
  verified by full regression of their existing test coverage.

## Assumptions

- LabSample (the external system that will eventually call this trigger) does
  not yet integrate with it, so the trigger's input contract (currently
  keyed by sample) is free to change to be keyed by measurement instead,
  with no breaking impact on any live external caller.
- The full-table email content (all measurements on the sample, resent in
  full for every trigger) is intentionally kept simple rather than narrowed
  to "only what's new since last send" — accepting that a contractor may
  receive multiple emails for the same sample over time, each showing an
  overlapping/growing table, in exchange for a much simpler and more robust
  implementation with fewer edge cases.
- Historical notification records created under the old sample-level tracking
  are left as inert history; no backfill or reprocessing of previously
  notified samples is performed or required.
- This fix does not change who receives notifications (recipient resolution)
  or which institution's template family (Toxo vs. lab) applies — only how
  "already notified" is tracked and at what granularity the trigger fires.
