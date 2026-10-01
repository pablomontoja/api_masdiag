# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## LSI.Masdiag QMS

This repository is the **Mailer** component of LSI.Masdiag, prefix **MA**. The default branch is **`main`**.

- The process is defined in the sibling repository `../lsi-masdiag-qms/`. Its `CLAUDE.md` takes precedence in matters of process (change IDs, skills, evidence, language of issues and PRs). Read the relevant skill in `../lsi-masdiag-qms/skills/<name>/SKILL.md` before doing process work.
- Change traces (`change.md`, `risk.md`, test results) live in `../lsi-masdiag-qms/changes/<ID>/`, not here. A change ID is `MA-<issue number>`.
- Branch: `<ID>-short-description`. Commit: starts with the ID, e.g. `MA-42: fix notification template`. Commits, branch names, code and code comments are in English; issues, PR descriptions and PR comments are in Polish (exception to any other language rule in this file).
- Work only on branches and open PRs to `main`.
- **Never** merge a PR (also via `gh api`), push to `main`, force-push, rewrite history, bypass hooks (`--no-verify`) or store tokens in the repository. Merging is the human's approval.
- Do not run tests in the working copy to record results; use a clean `git worktree` on the given SHA (`lsi-test-record`).
- Tests that verify a requirement carry RSpec metadata (the equivalent of `[Property("TC", ...)]` / `[Property("REQ", ...)]` in the .NET components): `it "...", tc: "TC-MA-001", req: "REQ-MA-001"`. A TC number is assigned once and never changes. Note: `../lsi-masdiag-qms/tools/traceability.sh` currently scans only `*.cs` files, so it does not yet read this metadata (to be settled in the QMS).
- The commands in "Commands" below were not verified when this section was added (no Ruby or database in the agent environment). Verify them in a clean worktree before recording any results.

## Project Overview

`api_masdiag` is a Rails 8 API-only application serving as a multi-tenant laboratory management system for diagnostic samples. It handles medical testing workflows (kits, samples, results, patient records) across multiple partner institutions.

## Commands

```bash
# Run all tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/requests/v1_sample_create_spec.rb

# Run a single example by line number
bundle exec rspec spec/requests/v1_sample_create_spec.rb:42

# Start the server
rvm use 3.4.10 && bin/rails s

# Rails console
rvm use 3.4.10 && bin/rails c

# Run background jobs (Solid Queue)
rvm use 3.4.10 && bin/rails solid_queue:start

# Database
rvm use 3.4.10 && bin/rails db:migrate
rvm use 3.4.10 && bin/rails db:migrate RAILS_ENV=test
```

## Architecture

### API Namespaces (config/routes.rb)

The API is versioned by namespace, each serving a different client type:

| Namespace | Purpose |
|-----------|---------|
| `v1/` | Polish domestic labs (full feature set) |
| `fv1/` | Foreign institutions (confirmation test activation) |
| `nume/` | NUME lab system |
| `lalen/` | Lalen partner (Australia/EU) — kit-focused operations |
| `toxo/` | Toxo portal (samples, measurements, registrations) |
| `masdiag/` | Internal Masdiag operations (notifications, setup) |
| `masdiag_mailer/` | Email notification endpoints |
| `patient_portal/` | Patient-facing endpoints (results, samples) — currently unused |
| `regspec/` | REGSPEC system (institutions, contractors, patients) |
| `diagnostyka_precyzyjna/` | Diagnostyka Precyzyjna integration (shop orders) |
| `webhook/` | Machine-to-machine webhooks (Bearer token auth, no ApiAccount) |

Eleven namespaces — `config/routes.rb` is authoritative if this table drifts.

### Authentication

HTTP Basic Auth on every request (`ApplicationController`). Credentials validated against `ApiAccount` (bcrypt via `has_secure_password`). The authenticated account is stored in `Current.api_account` (thread-local). Namespaces have additional authorization checks via concerns:
- `MasdiagCheck` — restricts to `institution_id == 1`
- `LalenCheck`, `NumeCheck` — partner-specific access

### Request Flow

```
Authenticate (HTTP Basic) → Authorize (concern) → Validate (namespace context) → Service → Alba serializer → json_response
```

### Service Objects

All complex business logic lives in `app/services/`. Base class: `ApplicationService`.

```ruby
result = SomeService.call(args)
result.success?   # true/false
result.payload    # return value on success
result.error      # error message on failure
```

Key services: `V1::SampleCreator`, `V1::WrongSampleUpdater`, `Notification::ResultService`, `Masdiag::ReservedSampleCodesCreator`.

### Domain Model Relationships

```
Institution → Contractor → ApiAccount (auth)
                         → Patient → Sample → Measurement (per Project)
                                               └── Result → AnalyteResult
ReservedSampleCode (barcode) → Package → Product
```

**Measurement status codes 1–7** represent workflow stages.

### Serialization

Uses **Alba** (not JBuilder/AMS). Serializers live in `app/resources/` and are named `*Resource`.

### Notification Dispatch (sample lifecycle emails)

LabSample reports a lifecycle **event** to a unified endpoint under the `masdiag` namespace (HTTP Basic + `MasdiagCheck`) — `POST /masdiag/{sample_accepted,sample_rejected,result_available,registration_reminder}`. It does **not** choose the email template. Each endpoint enqueues a `Notifications::*Job` that calls `Notifications::EventDispatcher`, which:

1. resolves the sample's institution (`Notifications::TemplateResolver`) — via the patient's contractor for registered samples, or via code → `ReservedSampleCode` → `Institution` for unregistered (virtual-patient) samples;
2. picks the template **family**: `:toxo` if the institution is in `V1::Common::TOXO_INSTITUTION_IDS`, else `:lab`;
3. for `:toxo`, builds `Toxo::SampleNotificationMailer` and routes through `Notifications::Sender` (idempotency via the `Note` model keyed per event on the Sample, plus `ResultSendingEvent`/`Fileable`/`DbFile` audit); for `:lab`, delegates to the existing lab mailers unchanged.

Order confirmation (event A) fires from the toxo portal's `Toxo::Samples::RegistrationsController#create` (Bearer + Pundit), not LabSample. The final registration reminder (event D) has no external trigger — `Notifications::RegistrationReminderFinalJob` runs daily via `config/recurring.yml`, using `business_time` (Polish holidays configured in `config/initializers/business_time.rb`) to count 7 working days from `AcceptanceDate`. Registration reminders (C/D) have no lab analog and are toxo-only.

### Background Jobs

**Solid Queue** (not Sidekiq). Jobs in `app/jobs/`. Pattern:

```ruby
retry_on StandardError, wait: :polynomially_longer, attempts: 5
```

`:exponentially_longer` was deprecated in Rails 7.1 and removed in 7.2 — use
`:polynomially_longer`, which all existing jobs already do.

Key jobs: `Notification::SendResultJob`, `MasdiagMailer::ContractorResultsNotifierJob`, `MasdiagMailer::PatientResultsNotifierJob`, `LalenApi::RegisterKitJob`, `Cerascreen::LabOrdatenbank::GetResultsJob`.

### Validation Contexts

Models use namespace-specific validation contexts (`:v1`, `:fv1`, `:lalen`) so the same model can enforce different rules per namespace.

### Encryption

**Lockbox** for field-level encryption (e.g., `ApiAccount#settings`, `OnlineFile` content). Keys come from Rails credentials. Never store plain credentials in fields marked encrypted.

### File Storage

MinIO (S3-compatible, self-hosted) via Active Storage in production. Disk in dev/test.

### Error Handling

Global handler via `ExceptionHandler` concern → returns 404/422 JSON. All exceptions captured to Sentry (GlitchTip at `glitchtip.masdiag.pl`, production only).

## Testing

RSpec with FactoryBot. Test type inferred from file location. Use `http_auth_header` helper from `spec/support/api_helpers.rb` for authenticated requests.

```ruby
# In request specs
get '/v1/samples', headers: http_auth_header(api_account)
json  # parses response.body as JSON
```

No fixtures — use factories exclusively.

## Key Conventions

- **Rails credentials** for all secrets (`bin/rails credentials:edit`)
- Patient deduplication by PESEL (Polish national ID) in `V1::SampleCreator`
- Institution-specific logic often branches on `institution_id` (id=1 is Masdiag)
- `V1::Common` (`app/lib/v1/common.rb`) holds shared constants: test codes, identity document types, Lalen institution IDs
- Composite primary keys used on some models — be careful with ActiveRecord finders
- `app/lib/` is autoloaded (configured in `application.rb`)

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at `specs/014-measurement-scoped-result-notifications/plan.md`.
<!-- SPECKIT END -->
