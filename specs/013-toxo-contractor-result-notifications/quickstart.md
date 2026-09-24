# Quickstart: Toxo Contractor Result Notifications Repair

## Verify the fix locally

1. **The cutoff date is a code constant**, not runtime-configurable (revised 2026-09-24 — see spec.md Clarifications). Check `Notifications::ResultAvailableJob::CUTOFF_DATE` for the current value; no console setup step is needed to configure it.

2. **Seed a Toxo sample with measurements** in different states (use FactoryBot factories, not fixtures), relative to `Notifications::ResultAvailableJob::CUTOFF_DATE`:
   - One measurement authorized *before* the cutoff (should never trigger a notification).
   - One measurement authorized *on/after* the cutoff, with an `OnlineFile`/PDF attached.
   - One measurement not yet authorized (`AuthorizedAt: nil`), no PDF.
   - Ensure the sample's patient's contractor belongs to an institution in `V1::Common::TOXO_INSTITUTION_IDS`, and has `allow_result_notifications: true`.

3. **Trigger the existing per-sample event** exactly as LabSample would:
   ```ruby
   Notifications::ResultAvailableJob.perform_now(sample.Id)
   ```

4. **Verify**:
   - Exactly one email was delivered (`ActionMailer::Base.deliveries` in test, or check Solid Queue / logs in dev).
   - The email body contains a table with **all three** measurements (not just the authorized one) — confirms User Story 2's "all measurements regardless of status."
   - The pre-cutoff-only case (a sample whose *only* authorized measurement is before the cutoff) produces **no** email — confirms User Story 1.
   - Re-running `Notifications::ResultAvailableJob.perform_now(sample.Id)` a second time sends **no** second email — confirms FR-008 (idempotency unchanged).

5. **Verify PDF links**: click (or curl) the link rendered for the measurement with an `OnlineFile` — it should resolve to the same file/URL shape currently returned by `GET /toxo/measurements/:id`'s `report_pdf_url` field.

## Running the test suite for this feature

```bash
bundle exec rspec spec/services/notifications/ spec/jobs/notifications/result_available_job_spec.rb spec/mailers/toxo/sample_notification_mailer_spec.rb spec/models/measurement_spec.rb
```

## Out of scope — do not test for these

- No backlog/recovery behavior exists — do not write a test expecting old, pre-fix samples to retroactively receive emails after deployment (see spec.md Clarifications, User Story 1 acceptance scenario 3).
- No change to `MasdiagMailer::EmailsController#send_all` / `ContractorResultsNotifierJob` — do not expect this fix to affect legacy lab-family email delivery.
