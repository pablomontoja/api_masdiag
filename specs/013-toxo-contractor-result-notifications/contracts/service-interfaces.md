# Contracts: Toxo Contractor Result Notifications Repair

This feature introduces no new public HTTP endpoints. `POST /masdiag/result_available` (`MasdiagCheck`-protected, called by LabSample) is unchanged — same request shape, same response. The "contracts" affected are internal service interfaces and the outbound email content, documented here since this is an API-only project with no external-facing route change.

## 1. `Notifications::ResultAvailableJob#perform` (unchanged signature, new internal behavior)

```
perform(sample_id: Integer) -> void
```

- **Unchanged**: still looks up `Sample.find_by(Id: sample_id)`, still returns silently if the sample is not found.
- **New**: before calling `Notifications::EventDispatcher.call(event: :result_available, sample:)`, the job checks sample eligibility (FR-001) via a private `#eligible?(sample)` method and returns early (no dispatch) if the sample has no measurement with `AuthorizedAt` on/after `CUTOFF_DATE`.
- **No new errors are introduced for the caller.** LabSample's `POST /masdiag/result_available` continues to receive the same response regardless of eligibility outcome — eligibility is evaluated asynchronously inside the enqueued job, not synchronously in the controller/endpoint.

## 2. `Notifications::ResultAvailableJob::CUTOFF_DATE` and `#eligible?` (revised 2026-09-24 — no separate service)

*Originally specified as a standalone `Notifications::ResultEligibility` service object backed by `KeyValueDbStore`-based runtime configuration; simplified per the user's explicit request after initial implementation. The service object and its spec were removed from the codebase.*

```ruby
CUTOFF_DATE = Date.new(2026, 9, 24).freeze  # class constant on the job

private

def eligible?(sample)
  sample.measurements.where("AuthorizedAt >= ?", CUTOFF_DATE).exists?
end
```

- **Input**: a `Sample` instance (already loaded, not `nil` — the job's `return if sample.nil?` guard runs first).
- **Output**: `true` if at least one of the sample's measurements has `AuthorizedAt` on/after `CUTOFF_DATE`; `false` otherwise (including when the sample has zero measurements).
- **Side effects**: none — read-only.
- **Configurability**: none at runtime. Changing the cutoff requires editing the constant and deploying. There is no "unconfigured" state to reason about — the constant always has a value.

## 3. `Toxo::SampleNotificationMailer#result_available` (extended, same public signature)

```
result_available(sample: Sample) -> Mail::Message
```

- **Unchanged**: signature, subject line ("Wynik badania"), delivery mechanism (still built by `EventDispatcher#dispatch_toxo` and delivered via `Notifications::Sender`).
- **New**: sets `@measurements = sample.measurements` (in addition to existing `@sample`, `@portal_url`) for the view to render the table.
- **No change** to `Notifications::Sender`'s idempotency contract (`Note` key `"result-available-email"`, one-shot per sample) — a sample that already has this `Note` is still skipped entirely by `Sender#already_sent?`, regardless of eligibility or table content changes.

## 4. Email content contract — `result_available.html.erb`

Given a sample and its `@measurements`, the rendered email MUST contain, for **every** measurement on the sample (User Story 2, "all measurements regardless of status"):

| Column | Source | Behavior when absent |
|---|---|---|
| Test/project name | `measurement.project.Name` (Mobility-translated) | N/A — always present |
| Status | `measurement.Status` | N/A — always present (integer 1–7, or label if one already exists in Toxo-facing code — see research.md §6) |
| Authorization date/time | `measurement.AuthorizedAt` | Blank/omitted cell, not an error, when `nil` (not yet authorized) |
| PDF link | `measurement.report_pdf_url` | No link element / non-clickable placeholder when `nil` (no PDF yet) — never a broken href |

This is a rendering contract only (HTML email body), not a machine-consumed API — verified via mailer/view specs (see research.md §7), not a JSON schema.

## 5. `KeyValueDbStore` — no new key (removed)

The originally planned `measurement_notification_cutoff_date`/`=` accessor pair was implemented, tested, then removed after the user's simplification request. `KeyValueDbStore` is unchanged by this feature — the cutoff date is a Ruby constant (§2), not a database-backed setting.
