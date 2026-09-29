# Phase 1 Data Model: Measurement-Scoped Result-Available Notifications

No new tables, columns, or migrations. This feature repurposes existing
entities and an existing generic mechanism (`Note`) at a different granularity
for one specific event.

## Entities touched

### `Measurement` (existing — `app/models/measurement.rb`, table `Measurements`)

No schema change. Existing relevant attributes/associations, unchanged:
- `belongs_to :sample` (required — `SampleId` NOT NULL, no `optional: true`)
- `belongs_to :project`
- `has_one :online_file`
- `AuthorizedAt` (datetime column) — becomes the sole eligibility signal for
  this event (previously checked across all of a sample's measurements, now
  checked against the single measurement being dispatched)
- `Status` (integer, workflow stage 1–7)
- `report_pdf_url` (existing instance method, added in feature 013) — unchanged

**New role in this feature**: becomes the `subject` of a `Note` for the
`"result-available-email"` key (previously only `Sample` held this key), and
becomes the primary argument threaded through
`ResultAvailableJob#perform` → `EventDispatcher.call(measurement:)` →
`Sender.call(measurement:)`.

### `Sample` (existing — `app/models/sample.rb`, table `Samples`)

No schema change. `has_many :measurements` unchanged. Continues to be the
entity whose `patient.contractor` determines the recipient, and whose full
`.measurements` collection is rendered in the Toxo email table — unchanged
content behavior, just no longer the *trigger* or *idempotency* subject for
this one event.

### `Note` (existing — `app/models/note.rb`, table `notes`)

No schema change. `Note.subject_type`/`subject_id` are already generic
polymorphic columns (`string`/`bigint`) with no FK/CHECK constraint tying them
to a specific class; `KEYS_BY_SUBJECT` is a pure in-code Ruby constant enforced
by `validates_inclusion_of :key, in: :available_keys`.

**Change**: `KEYS_BY_SUBJECT["Measurement"]` gains `"result-available-email"`:

```ruby
"Measurement" => %w[
  included-in-monthly-hospital-report
  included-in-daily-hospital-zip-archive
  included-in-monthly-ptc-report
  included-in-monthly-invoice-for-hospitals
  omegaquant-result-exit-in-csv
  result-available-email          # NEW
  lab-user-note
]
```

`KEYS_BY_SUBJECT["Sample"]` keeps `"result-available-email"` too (it must — the
other five events still use it, and historical Sample-scoped `Note` rows from
before this fix remain valid, inert history; see below). The same string key
is now legitimately used under two different `subject_type`s, which `Note`'s
existing scoped-uniqueness validation (`scope: [:subject_type, :key]`) already
supports without ambiguity — a `Sample`-scoped and a `Measurement`-scoped
`Note` with the same `key` are distinct records by design.

**Historical data**: `Note` rows already created as
`(subject_type: "Sample", subject_id: <sample.Id>, key: "result-available-email")`
under the old (buggy) code path are left untouched — inert history, not
queried by the new code, not backfilled into per-measurement rows (there is no
reliable way to know which single measurement "caused" a historical
sample-level send).

### `ResultSendingEvent` (existing, via `Fileable`/`Sender#record_audit`)

No schema change. `event.measurement` — an existing, previously-unused
(`nil`-only) association slot on this audit record for the Toxo path — is now
populated with the triggering `Measurement` when present, matching how the
`:lab` family's `ContractorResultNotificationMailer#set_sendmail` already
populates it per file.

### `OnlineFile` (existing — legacy `:lab` family idempotency, unaffected in shape)

No schema change. `is_notification_send` (boolean) continues to be the
per-file idempotency flag for the `:lab` family. **Behavioral change only**:
`EventDispatcher#lab_result_file_ids` now filters to
`where(is_notification_send: false)` before dispatch, so previously-sent files
are never re-included (see research.md decision 5).

## State / lifecycle notes

- A `Measurement`'s notification lifecycle for this event is now: not yet
  eligible (before `AuthorizedAt` or before `CUTOFF_DATE`) → eligible, not yet
  sent → sent (one `Note` created, permanently idempotent for that
  measurement). This mirrors the lifecycle `Sample` used to have for this
  event, just at finer grain.
- A `Sample`'s aggregate notification state is now simply "the union of its
  measurements' individual states" — there is no longer a single
  sample-level "has been notified" flag for this event, by design (that
  single flag was the bug).

## Relationships summary

```
Sample 1 ──< many Measurement
Measurement 1 ──1 OnlineFile (existing)
Measurement 1 ──< many Note (subject_type: "Measurement") [NEW usage of existing polymorphic assoc]
Sample 1 ──< many Note (subject_type: "Sample") [unchanged, other 5 events]
Measurement 1 ──0..1 ResultSendingEvent.measurement [NEW: now populated for Toxo path]
```
