# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`api_masdiag` is a Rails 7 API-only application serving as a multi-tenant laboratory management system for diagnostic samples. It handles medical testing workflows (kits, samples, results, patient records) across multiple partner institutions.

## Commands

```bash
# Run all tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/requests/v1_sample_create_spec.rb

# Run a single example by line number
bundle exec rspec spec/requests/v1_sample_create_spec.rb:42

# Start the server
rvm use 3.1.2 && bin/rails s

# Rails console
rvm use 3.1.2 && bin/rails c

# Run background jobs (Solid Queue)
rvm use 3.1.2 && bin/rails solid_queue:start

# Database
rvm use 3.1.2 && bin/rails db:migrate
rvm use 3.1.2 && bin/rails db:migrate RAILS_ENV=test
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
| `masdiag/` | Internal Masdiag operations (notifications, setup) |
| `masdiag_mailer/` | Email notification endpoints |
| `patient_portal/` | Patient-facing endpoints (results, samples) |
| `regspec/` | REGSPEC system (institutions, contractors, patients) |

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

### Background Jobs

**Solid Queue** (not Sidekiq). Jobs in `app/jobs/`. Pattern:

```ruby
retry_on StandardError, wait: :exponentially_longer, attempts: 5
```

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
