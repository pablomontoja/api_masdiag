# Quickstart: Measurement-Scoped Result-Available Notifications

## Prerequisites

- On branch `014-measurement-scoped-result-notifications` (created from `013-toxo-contractor-result-notifications`).
- `rvm use 3.4.10`, local MySQL running, `bin/rails db:migrate RAILS_ENV=test` up to date (no new migration this feature).

## Running the test suite for this feature

```bash
bundle exec rspec \
  spec/models/note_spec.rb \
  spec/services/notifications/event_dispatcher_spec.rb \
  spec/services/notifications/sender_spec.rb \
  spec/jobs/notifications/result_available_job_spec.rb \
  spec/requests/masdiag/result_available_spec.rb \
  spec/mailers/toxo/sample_notification_mailer_spec.rb
```

Also run these to confirm no regression (expected: unchanged pass, per
plan.md's Constitution Check and research.md decision 1):

```bash
bundle exec rspec \
  spec/services/notifications/recipient_resolver_spec.rb \
  spec/services/notifications/template_resolver_spec.rb \
  spec/models/measurement_spec.rb
```

## Manual verification scenario (the direct bug-report regression test)

In a Rails console (development or a scratch/transactional test context —
never leave stray records in a shared dev DB):

```ruby
sample = create(:sample) # or find a real multi-measurement Toxo sample
m1 = create(:measurement, sample: sample, project: create(:project_without_fixed_id), AuthorizedAt: Notifications::ResultAvailableJob::CUTOFF_DATE.in_time_zone + 1.day)
m2 = create(:measurement, sample: sample, project: create(:project_without_fixed_id), AuthorizedAt: Notifications::ResultAvailableJob::CUTOFF_DATE.in_time_zone + 2.days)

Notifications::ResultAvailableJob.perform_now(m1.Id)
# => expect 1 email sent, containing the full measurements table + a sentence naming m1's project

Notifications::ResultAvailableJob.perform_now(m2.Id)
# => expect a SECOND, distinct email sent (this is the bug fix — previously silently skipped)
# each email's table shows all of sample.measurements as of that send

Note.where(subject_type: "Measurement", subject_id: [m1.Id, m2.Id], key: "result-available-email").count
# => expect 2 (one Note per measurement)
```

## Legacy `:lab` family regression check

```ruby
lab_sample = create(:sample) # institution NOT in V1::Common::TOXO_INSTITUTION_IDS
lm1 = create(:measurement, sample: lab_sample, project: create(:project_without_fixed_id))
create(:online_file, measurement: lm1, is_notification_send: false)

Notifications::EventDispatcher.call(event: :result_available, measurement: lm1)
# => expect 1 lab email sent, OnlineFile#is_notification_send now true

Notifications::EventDispatcher.call(event: :result_available, measurement: lm1)
# => expect NO second email (file already marked sent) — this is the regression guard from research.md decision 5
```

## Deployment notes

No database migration required. Deploying the code alone is sufficient —
`Note::KEYS_BY_SUBJECT` and route changes take effect immediately on deploy.
