# Data Model: Toxo Contractor Result Notifications Repair

No new database tables or columns are introduced. This feature reuses existing tables/models and adds a small number of new methods/keys on top of them.

## Existing entities involved (unchanged schema)

### Sample
- Table: `Samples`. Unit of notification eligibility, recipient resolution, and idempotency.
- Relevant existing associations: `has_many :measurements`, `belongs_to :patient`.
- No schema change. Used read-only by the eligibility check inside `Notifications::ResultAvailableJob`.

### Measurement
- Table: `Measurements`. Relevant existing attributes: `Id`, `SampleId`, `ProjectId`, `Status` (integer, workflow stage 1–7), `AuthorizedAt` (datetime, nullable — absent until authorized).
- Relevant existing associations: `belongs_to :sample`, `belongs_to :project`, `has_one :online_file`.
- No schema change.
- **New method** (proposed): `Measurement#report_pdf_url` — returns the same signed Active Storage URL as `Toxo::MeasurementSerialization#unencrypted_result_url` (`nil` when no PDF is available yet). Moves/reuses that 2-line `prepare_active_storage; url_for(...)` logic onto the model so both the controller concern and the mailer can call it without duplication. (See research.md §5 for the `url_for`/`default_url_options` host-configuration caveat that must be verified in mailer context.)

### Project
- Table: `Projects`. Relevant existing attribute: `Name` (Mobility-translated, see `Project#Name`/`Project#Name=`).
- No schema change. Used read-only to render the test/project display name per row.

### Contractor
- Table: `Contractors`. Relevant existing attribute: `allow_result_notifications` (boolean, default `true`).
- No schema change. Existing `Notifications::RecipientResolver` already gates on this flag for `:result_available` — unchanged by this feature.

### OnlineFile
- Table backing `has_one :online_file` on `Measurement`. Relevant existing attributes: `file_contents` (presence indicates a PDF exists), Active Storage attachment `unencrypted_result`.
- No schema change. Read-only source for the PDF link.

### Note (idempotency marker)
- Existing polymorphic model; `(subject_type: "Sample", subject_id:, key: "result-available-email")` uniqueness enforces one-shot-per-sample.
- No schema change, no behavior change — reused exactly as-is (FR-008).

## Cutoff date (revised 2026-09-24 — no configuration storage)

Originally planned as a `KeyValueDbStore`-backed runtime setting (see research.md's revision note). Per the user's explicit simplification request, the final implementation instead defines it as a plain Ruby constant:

```ruby
module Notifications
  class ResultAvailableJob < ApplicationJob
    CUTOFF_DATE = Date.new(2026, 9, 24).freeze
    # ...
  end
end
```

No database row, no getter/setter pair, no `config_entries` involvement. Changing the cutoff requires editing this constant and deploying — an accepted tradeoff since the value is expected to be set once, not adjusted routinely by operators.

## New/changed behavior (no new persisted entities)

### Notifications::ResultAvailableJob — inline eligibility check
- Not a service object (revised — see plan.md's Constitution Check note: a standalone `Notifications::ResultEligibility` was built, tested, then removed as unnecessary ceremony for a one-line check).
- A private method `#eligible?(sample)` on the job: `sample.measurements.where("AuthorizedAt >= ?", CUTOFF_DATE).exists?`.
- No schema implications; purely a query against existing `Measurements.AuthorizedAt`.

### Toxo::SampleNotificationMailer#result_available
- Existing method, gains a new instance variable `@measurements` (from `sample.measurements`, already loaded association — no new query object required, per constitution's "1–2 conditions → use association/scope" threshold, not a query object).
- No schema implications.

## Relationships summary (unchanged)

```
Sample 1---* Measurement *---1 Project
Sample 1---1 (via patient) Contractor
Measurement 1---1 OnlineFile (PDF source)
Sample 1---* Note (idempotency markers, keyed by event)
```

No relationship changes. This feature is additive at the service/mailer/view layer and reuses one existing generic config-storage model for a new key.
