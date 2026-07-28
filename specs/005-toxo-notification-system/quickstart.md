# Quickstart — Unified Notification System (Toxo + Lab)

Exercise each lifecycle event through the unified `masdiag` endpoints and verify api_masdiag picks the right template family by institution.

## Prerequisites

```bash
rvm use 3.1.2
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
bundle exec rspec
```

Confirm the toxo institution constant and business-day config:
```bash
bin/rails runner 'p V1::Common::TOXO_INSTITUTION_IDS'
bin/rails runner 'p Date.new(2026,7,1) + 7.business_days'   # excludes weekends + PL holidays
```

## Trigger each event (LabSample-facing, HTTP Basic + MasdiagCheck)

```bash
curl -u <masdiag_user>:<pass> -H 'Content-Type: application/json' \
  -d '{"sample_id": 12345}' http://localhost:3001/masdiag/sample_accepted    # B
curl -u <masdiag_user>:<pass> -H 'Content-Type: application/json' \
  -d '{"sample_id": 12345}' http://localhost:3001/masdiag/sample_rejected     # E
curl -u <masdiag_user>:<pass> -H 'Content-Type: application/json' \
  -d '{"sample_id": 12345}' http://localhost:3001/masdiag/result_available    # F
curl -u <masdiag_user>:<pass> -H 'Content-Type: application/json' \
  -d '{"code": "MD_12345"}'  http://localhost:3001/masdiag/registration_reminder  # C
```
Each returns `200 "OK"` and enqueues the matching job. LabSample sends the **same** request whether the sample is toxo or not.

## Verify template selection by institution

```bash
bin/rails runner '
  toxo   = Sample.find(<toxo_sample_id>)      # institution ∈ TOXO_INSTITUTION_IDS
  lab    = Sample.find(<lab_sample_id>)        # any other institution
  Notifications::SampleAcceptedJob.perform_now(toxo.Id)
  Notifications::SampleAcceptedJob.perform_now(lab.Id)
  puts ActionMailer::Base.deliveries.last(2).map { |m| m.subject }
  # expect the toxo one to use the Toxo::SampleNotificationMailer subject,
  # the lab one to use the existing lab acceptance subject
'
```

## Event A — order confirmation (portal, Bearer auth)
Register a toxo sample via `POST /toxo/samples/registrations` with a session token. On success `Notifications::SampleRegistrationConfirmationJob` enqueues; the dispatcher selects the toxo confirmation template and attaches the PDF.

## Event D — final reminder (recurring)
Daily via `config/recurring.yml`. Manual run:
```bash
bin/rails runner 'Notifications::RegistrationReminderFinalJob.perform_now'
```
Selects toxo-institution samples with `AcceptanceDate` set, patient still virtual, ≥7 business days past `AcceptanceDate`, and no `registration-reminder-final-email` Note.

## Verify idempotency (family-neutral)

```bash
bin/rails runner '
  s = Sample.find(12345)
  Notifications::SampleAcceptedJob.perform_now(s.Id)
  before = ActionMailer::Base.deliveries.size
  Notifications::SampleAcceptedJob.perform_now(s.Id)
  after  = ActionMailer::Base.deliveries.size
  puts "notes: #{Note.where(subject: s, key: "sample-accepted-email").count} (expect 1)"
  puts "no-resend: #{before == after} (expect true)"
'
```

## Verify audit
Each send writes a `ResultSendingEvent` (`sent_through = 1`) with rendered HTML stored as a `DbFile` via a `Fileable`, appearing in the same sent-history LabSample already reads — for both families.

## Test suite
```bash
bundle exec rspec spec/services/notifications                       # dispatcher, template_resolver, recipient_resolver, sender, finder
bundle exec rspec spec/jobs/notifications
bundle exec rspec spec/mailers/toxo/sample_notification_mailer_spec.rb
bundle exec rspec spec/requests/masdiag/notifications_spec.rb        # unified endpoints
bundle exec rspec spec/requests/toxo/samples/registrations_order_confirmation_spec.rb
```
