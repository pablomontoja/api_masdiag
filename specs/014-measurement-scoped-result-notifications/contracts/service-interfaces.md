# Phase 1 Contracts: Measurement-Scoped Result-Available Notifications

This feature's only external-facing interface is the `masdiag` namespace HTTP
endpoint. Internal service-object signatures are documented here too since
they are the contracts other code in this codebase (and its specs) depend on.

## 1. `POST /masdiag/result_available/:measurement_id`

**Change from current contract**: path param renamed from `:sample_id` to
`:measurement_id`; the ID identifies a `Measurement`, not a `Sample`.

**Auth**: HTTP Basic (`ApiAccount`) + `MasdiagCheck` (institution_id == 1) —
unchanged.

**Request**: `POST /masdiag/result_available/:measurement_id` (JSON, no body
required — id is a path param, matching the existing pattern for this
endpoint family).

**Responses**:
- `200 OK`, body `"OK"` — measurement found, job enqueued. (Enqueuing does not
  guarantee an email is sent — eligibility/idempotency still apply
  downstream.)
- `422 Unprocessable Content`, body `{ "error": "measurement not found" }` —
  no `Measurement` with that `Id` exists. (Error message text changes from
  `"sample not found"` to `"measurement not found"` to match the new
  contract.)

**Breaking change acknowledgment**: This changes the existing (already-shipped
but not-yet-externally-consumed) contract. Confirmed safe: LabSample does not
yet call this endpoint (stated assumption in spec.md).

## 2. `Notifications::EventDispatcher.call`

**Before**:
```ruby
Notifications::EventDispatcher.call(event:, sample:)
```

**After**:
```ruby
Notifications::EventDispatcher.call(event:, sample: nil, measurement: nil)
```

**Contract per event**:
| Event | Required keyword |
|---|---|
| `:sample_accepted` | `sample:` |
| `:sample_rejected` | `sample:` |
| `:sample_registration_confirmation` | `sample:` |
| `:registration_reminder` | `sample:` |
| `:registration_reminder_final` | `sample:` |
| `:result_available` | `measurement:` |

Calling `:result_available` without `measurement:`, or any other event
without `sample:`, raises `ArgumentError` (fail fast — no silent skip).

`@sample` is always derived internally as `measurement&.sample || sample`, so
every downstream collaborator (`TemplateResolver`, `RecipientResolver`,
`dispatch_lab`) continues to receive a `Sample` exactly as before.

## 3. `Notifications::Sender.call`

**Before**:
```ruby
Notifications::Sender.call(sample:, event:, mail:, recipient:, family:)
```

**After**:
```ruby
Notifications::Sender.call(event:, mail:, recipient:, family:, sample: nil, measurement: nil)
```

Idempotency subject (`Note.subject`) is `measurement || sample` — whichever is
passed. All five non-`:result_available` events keep calling with `sample:`
only, exactly as today; no change to their call sites or specs.

## 4. `Notifications::ResultAvailableJob#perform`

**Before**: `perform(sample_id)` — looks up `Sample`, checks
`sample.measurements.where("AuthorizedAt >= ?", CUTOFF_DATE).exists?`.

**After**: `perform(measurement_id)` — looks up `Measurement`, checks
`measurement.AuthorizedAt.present? && measurement.AuthorizedAt >= CUTOFF_DATE`.
`CUTOFF_DATE` constant value and semantics unchanged.

## 5. `Toxo::SampleNotificationMailer#result_available`

**Before**: `result_available(sample)` — sets `@measurements = sample.measurements`.

**After**: `result_available(sample, measurement)` — additionally sets
`@triggering_measurement = measurement`. `@measurements = sample.measurements`
unchanged (full table, every send).

View gains one sentence using `@triggering_measurement.project.Name`; existing
table rendering (`@measurements.each`) is untouched.

## 6. `Note::KEYS_BY_SUBJECT`

**Before**: `"result-available-email"` valid only for `subject_type: "Sample"`.

**After**: `"result-available-email"` valid for both `subject_type: "Sample"`
(kept, for the other five events and for historical rows) and
`subject_type: "Measurement"` (new, used exclusively by this event going
forward).

## 7. `EventDispatcher#lab_result_file_ids` (private, no external contract change, behavior change only)

**Before**: `OnlineFile.joins(measurement: :sample).where(Samples: { Id: @sample.Id }).pluck(:measurement_id)` — all files for the sample, every call.

**After**: adds `.where(is_notification_send: false)` — only not-yet-delivered
files. `dispatch_lab`'s `:result_available` branch skips (returns
`Sender::Result.new(status: :skipped)`) when this list is empty.
