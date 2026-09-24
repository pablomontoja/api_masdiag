# Research: Toxo Contractor Result Notifications Repair

> **Revision note (2026-09-24, post-implementation)**: §2 and §3 below describe the *originally planned* design — `KeyValueDbStore`-backed runtime configuration plus a standalone `Notifications::ResultEligibility` service object. After implementing and testing that design, the user judged it over-engineered for a cutoff date meant to be set once at deploy time, not adjusted routinely. The actual, final implementation instead uses a plain Ruby constant `Notifications::ResultAvailableJob::CUTOFF_DATE`, checked inline via a private method on the job — no separate service object, no `KeyValueDbStore` accessor. §2 and §3 are kept below as a record of the alternatives considered and why the original design was chosen, but they no longer describe what shipped. See spec.md's Clarifications (session 2026-09-24, post-implementation revision) for the user's reasoning, and plan.md's Constitution Check for the updated layering rationale.

## 1. Root cause and integration point

**Decision**: The gating logic (cutoff date) and the measurement table both belong inside the existing `:toxo`-family `result_available` dispatch path (`Notifications::EventDispatcher#dispatch_toxo` → `RecipientResolver` → `Toxo::SampleNotificationMailer#result_available` → `Sender`), not in the legacy `send_all`/`ContractorResultsNotifierJob` path.

**Rationale**: Investigation (see spec.md "Background") confirmed two independent pipelines. `ContractorResultsNotifierJob` is gated by `Contractor#are_notifications_enabled` (defaults `false`, unrelated to Toxo) and has zero institution awareness. Toxo notifications already flow exclusively through `Notifications::EventDispatcher`, triggered per-sample via `Notifications::ResultAvailableJob` (itself invoked from `POST /masdiag/result_available`, `MasdiagCheck`-protected). This is the correct, sole integration point — extending it is additive and requires no change to the legacy path (satisfies FR-004).

**Alternatives considered**:
- Add `ResultAvailableJob` calls into `send_all` — rejected per the user's own stated concern (risk of duplicate sends; `send_all` has no per-sample scoping) and reconfirmed by clarification (no backlog recovery wanted at all).
- Introduce a new bulk mailer job — unnecessary; the per-sample trigger already exists and works correctly for samples where LabSample calls it. Nothing here indicates the trigger call itself is broken; the fix is about *what* the trigger does once invoked (apply the cutoff gate, render the table), not about re-architecting *when* it's invoked.

## 2. Cutoff date storage mechanism

**Decision**: Store the cutoff date as a new key/value pair on the existing `KeyValueDbStore` model (`app/models/key_value_db_store.rb`, backed by the `config_entries` table), following the established `metanephrine_settled_samples` / `metanephrine_settled_samples=` getter/setter convention. New accessor pair: `KeyValueDbStore.measurement_notification_cutoff_date` / `KeyValueDbStore.measurement_notification_cutoff_date=`.

**Rationale**: Explicit codebase-wide survey (see prior investigation) found exactly one existing mechanism for values an operator can change without a deploy: `KeyValueDbStore`/`config_entries`. Alternatives were surveyed and rejected:
- Rails credentials (`config/credentials.yml.enc`) — used nowhere in the app for non-secret operational config; reserved for actual secrets per constitution Principle IV.
- `Rails.application.config.x.*` / bare `Rails.configuration.*` mutable attributes — the one precedent (`last_use_of_send_all_mail`) is process-memory-only, reset on every deploy/restart, not shared across app servers/workers. Unsuitable for a value that must persist and be operator-adjustable.
- `ENV["..."]` — reserved in this app exclusively for infra/deploy toggles (`RAILS_SERVE_STATIC_FILES`, `CI`, etc.), never business-domain config.
- A hardcoded Ruby constant (the shape used by `RegistrationRemindersFinder::WORKING_DAYS`) — rejected because the spec's FR-002 explicitly requires the cutoff be adjustable without a code change; a constant would require a deploy for every adjustment.

**Alternatives considered**: A dedicated new `Setting`/`SystemConfig` ActiveRecord model was considered but rejected as premature — `KeyValueDbStore` already exists for exactly this purpose and the constitution's "New directories MUST NOT be added without a constitution amendment" combined with "MUST NOT abstract when... used only once" favors reusing the existing generic store over introducing a second settings mechanism.

## 3. Eligibility gate placement

**Decision**: Add an eligibility check — "does this sample have at least one measurement with `AuthorizedAt >= cutoff_date`?" — as a new, narrowly-scoped service object `Notifications::ResultEligibility` (or equivalent single-purpose check), invoked from `Notifications::ResultAvailableJob` before calling `EventDispatcher.call`. If the sample is not eligible, the job returns early (no dispatch, no `Note`, no audit trail — mirrors the existing "return if sample.nil?" early-return shape already in that job).

**Rationale**: Keeps the cutoff concern entirely inside the `:toxo` `result_available` path (does not touch `:lab` family or other events per FR precedent of non-interference), avoids growing `EventDispatcher`/`Sender` with event-specific eligibility logic that only applies to one event, and matches the "Service Object" layer boundary from constitution Principle II/VI (business rule — not HTTP, not display). Checking in the job (before dispatch) rather than inside `dispatch_toxo` also means an ineligible sample never consumes/creates a `Note`, so if it later gains a qualifying measurement, the sample is *not* prematurely marked as already-notified — consistent with FR-008's idempotency guarantee only applying once a notification is actually sent.

**Alternatives considered**: Filtering inside `RecipientResolver` was rejected — that service's stated responsibility (per its own doc comment) is resolving *who* receives the notification, not *whether* the event should fire at all; conflating the two would violate single-responsibility and make the class harder to reuse for other events that have no cutoff concept.

## 4. Measurement table data source and rendering

**Decision**: The `result_available` mailer method gains an additional instance variable, `@measurements`, populated from `sample.measurements` (already an existing `has_many` association, no new query object needed — it's a simple 1-2 condition association load, not a 3+ join aggregation per constitution's "MUST NOT abstract" threshold). The view iterates `@measurements`, rendering columns via existing model accessors: `measurement.project.Name` (Mobility-translated per-locale automatically via `Project#Name`/`Project#Name=` override), `measurement.Status`, `measurement.AuthorizedAt`, and a PDF link.

**Rationale**: `Measurement belongs_to :project`, `Project` already exposes a translated `Name`. No new model code needed for name/status/date columns — purely a view-layer (ERB) and mailer-instance-variable change, which per constitution's Mailer layer ("Email composition") and Presenter layer ("View formatting, badges, display") boundaries stays correctly scoped: the mailer composes, the view formats.

**Alternatives considered**: A dedicated Presenter/decorator per measurement row was considered (`app/presenters/`) but deferred as premature per the "MUST NOT abstract when... formatting is trivial" rule — the four required columns (name, status label, date, link) are simple attribute reads/formats, not complex display logic. If status needs a human-readable label beyond the raw integer (see below), a small private helper method in the mailer or a simple constant map is sufficient without a full presenter class.

## 5. PDF link generation for the email

**Decision**: Reuse the exact same mechanism already used by `app/controllers/concerns/toxo/measurement_serialization.rb#unencrypted_result_url` — `measurement.online_file.prepare_active_storage; url_for(measurement.online_file.unencrypted_result)` — to compute each measurement's PDF link in the mailer. This is the same signed Active Storage URL the Toxo portal's own `/results` page already renders directly as an `<a href>` (confirmed by inspecting the separate `toxo` frontend app: `app/views/results/index.html.erb` embeds `measurement.report_pdf_url` as a raw `href`, `target: "_blank"`, no toxo-session gate on the link itself beyond reaching the page that reveals it).

**Rationale**: Per clarification, this is the explicitly chosen approach — no new link/proxy mechanism, reuse the existing signed-URL pattern for consistency and to avoid introducing a second access-control model for the same underlying file.

**Implementation note**: `unencrypted_result_url` is currently a **private method inside a controller concern** (`Toxo::MeasurementSerialization`), which depends on `url_for` being available in a controller context. Action Mailer views/mailers also have `url_for` available (via `Rails.application.routes.url_helpers` / `AbstractController::UrlFor`, standard in `ApplicationMailer`), but the *mailer* context requires `default_url_options[:host]` (and optionally `:protocol`) to be configured for the URL to be absolute rather than raising `ActionController::UrlGenerationError` for a missing host. Need to verify `config.action_mailer.default_url_options` is already set in `config/environments/production.rb`/`staging.rb`/`development.rb` (existing mailers like `sample_registration_confirmation` already attach a rendered file rather than a link, so this may not yet be exercised for link-generation-in-mailer). The link-building logic itself should be extracted to a small shared method (not duplicated) — either a `Measurement` model method (e.g. `#report_pdf_url` mirroring the controller concern's naming, since the model already owns `online_file`) or a private helper in the mailer, whichever avoids duplicating the two-line `prepare_active_storage; url_for(...)` sequence between controller and mailer. Given the logic is tiny (2 lines) and touches an association (`online_file`) the model already owns, adding a `Measurement#report_pdf_url` instance method is the most Rails-conventional home — consistent with "Model | Validations, associations, scopes" plus simple derived-attribute methods already present elsewhere in this codebase (e.g. `Sample#hasResult?`).

**Alternatives considered**: A brand-new PDF-serving controller action / signed token scheme was rejected outright by the clarification answer. Fetching PDF bytes and attaching them to the email (like `sample_registration_confirmation`'s Prawn attachment) was also considered and rejected — the sample can have multiple measurements/PDFs, and the point of the table is lightweight discoverability with one-click access, not bundling potentially several PDFs as attachments (also inconsistent with the chosen "reuse the portal's link" approach).

## 6. Status display

**Decision**: Render `Measurement#Status` (integer 1–7 per CLAUDE.md) directly, or via a minimal label map if a human-readable string already exists elsewhere in Toxo-facing code (worth a final check during implementation for an existing status-label constant in `Toxo::MeasurementSerialization`, `Toxo::Constants`, or similar, before introducing a new one).

**Rationale**: Constitution explicitly prohibits "Stringly Typed constants" and mandates reusing `V1::Common`-style shared constants over ad hoc mappings. If no existing label map is found, the raw status integer is an acceptable interim display (matches what the JSON API already exposes via `Toxo::MeasurementSerialization#serialize_measurement`'s `Status:` field) rather than inventing a new, possibly-duplicate label constant during this fix.

## 7. Testing approach

**Decision**: Follow constitution Principle III (test-first, RSpec, FactoryBot only). New/changed specs needed at each touched layer:
- `spec/services/notifications/result_eligibility_spec.rb` (or equivalent) — unit tests for the cutoff gate logic (measurement on/after cutoff → eligible; before cutoff → not eligible; no measurements → not eligible).
- `spec/jobs/notifications/result_available_job_spec.rb` — extend existing spec to cover the new early-return-when-ineligible branch.
- `spec/mailers/toxo/sample_notification_mailer_spec.rb` (create if absent) or a mailer preview/request-level check — verify `@measurements` is populated and the rendered view contains one row per measurement with correct name/status/date/link, including the "no PDF yet" and "not yet authorized" row variants from spec.md User Story 2's acceptance scenarios.
- `spec/models/key_value_db_store_spec.rb` — extend for the new getter/setter pair if not already generically covered.

**Rationale**: Matches the existing test-type-per-layer convention already visible in `spec/services/notifications/`, `spec/jobs/notifications/`, and mirrors how `event_dispatcher_spec.rb`/`sender_spec.rb` are structured today.
