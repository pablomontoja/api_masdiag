# Contract: Unified lifecycle-event endpoints (`masdiag` namespace)

LabSample calls **one endpoint per lifecycle event**. It never chooses lab-vs-toxo template — api_masdiag decides server-side from the sample's institution.

**Auth**: HTTP Basic (`ApplicationController`) + `MasdiagCheck` (institution_id == 1). Same auth LabSample already uses for `masdiag`/`masdiag_mailer`.

**Format**: `defaults: { format: :json }`. Controller: authenticate → `MasdiagCheck` → validate sample id/code → enqueue event job → `json_response`.

**Common behavior**:
- Success: enqueue the matching `Notifications::<Event>Job` → `200` `"OK"` (or `{ message: "notification scheduled" }`).
- Missing/unknown sample: `422` `{ "error": "sample not found" }`.
- Unexpected error: `500` `{ "error": "<message>" }` (+ Sentry in production).
- Template family selection, recipient resolution, idempotency (Note), and audit all happen in the job/dispatcher — not the endpoint. Duplicate calls return `200` and send no second email.

Routes to add under `namespace :masdiag`:

```ruby
post "sample_accepted",              to: "notifications#sample_accepted"       # B
post "registration_reminder",        to: "notifications#registration_reminder" # C
post "sample_rejected",              to: "notifications#sample_rejected"        # E
post "result_available",             to: "notifications#result_available"       # F
# A (order_confirmation) normally fires from the toxo portal (see toxo-order-confirmation.md);
# optionally expose post "order_confirmation" for lab-originated confirmations.
```

---

## POST /masdiag/sample_accepted  (Event B)
Body: `{ "sample_id": 12345 }`
→ `Notifications::SampleAcceptedJob.perform_later(sample_id)`. Dispatcher picks toxo vs lab acceptance template by institution. `200 "OK"`.

## POST /masdiag/registration_reminder  (Event C)
Body: `{ "sample_id": 12345 }` **or** `{ "code": "MD_12345" }` (unregistered delivery may only have the code).
→ `Notifications::RegistrationReminderJob.perform_later(sample_id_or_code)`. Recipient = code → RSC → `institution.email_for_notifications`. Toxo institutions get the toxo reminder template (no lab analog exists). `200 "OK"`.

## POST /masdiag/sample_rejected  (Event E)
Body: `{ "sample_id": 12345 }`
→ `Notifications::SampleRejectedJob.perform_later(sample_id)`. Toxo rejection email includes sample code, sample/package number, client internal number (if present), material type, ordered tests, execution mode (CITO/Standard). Non-toxo → existing cancellation template. `200 "OK"`.

## POST /masdiag/result_available  (Event F)
Body: `{ "sample_id": 12345 }`
→ `Notifications::ResultAvailableJob.perform_later(sample_id)`. `200 "OK"`.

---

## Template-family resolution (server-side)

```
job → Notifications::EventDispatcher.call(event:, sample:)
        institution = TemplateResolver.institution_for(sample)   # via code→RSC→institution (or contractor for registered)
        family = institution.id.in?(V1::Common::TOXO_INSTITUTION_IDS) ? :toxo : :lab
        mailer = family == :toxo ? Toxo::SampleNotificationMailer : <existing lab mailer for event>
        Notifications::Sender.call(sample:, event:, mailer:, recipient:)   # Note guard + deliver + audit + mark Note
```

## Skip semantics (all events)
Skip (no email, reason recorded, no error) when: a `Note` for this sample + event already exists; the recipient email is blank / notifications disabled; or the sample cannot be resolved. Non-toxo delegation preserves existing lab-mailer guards (e.g. skipping samples tied to an `api_account`).
