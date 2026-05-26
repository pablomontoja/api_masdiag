<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Bump rationale: MINOR — new principle added (VI. Layered Architecture & Abstraction Thresholds),
  canonical directory structure section added, anti-patterns section added.
Modified principles:
  II. Service-Object Architecture — expanded with layer responsibility table and abstraction signals
Added sections:
  VI. Layered Architecture & Abstraction Thresholds
  Canonical Directory Structure
  Anti-Patterns (prohibited)
Removed sections: None
Templates requiring updates:
  ✅ plan-template.md — Constitution Check now covers principles I–VI
  ✅ spec-template.md — no changes needed
  ✅ tasks-template.md — no changes needed
  ✅ commands/*.md — no commands dir present
Deferred TODOs: None
-->

# api_masdiag Constitution

## Core Principles

### I. Rails Conventions Over Configuration

All code MUST follow Rails conventions. Configuration exists only where the framework requires it.
Routes, models, controllers, jobs, and serializers follow Rails naming and structural norms.
Deviations MUST be documented with explicit rationale in the relevant file or PR description.
Namespace separation (`v1/`, `fv1/`, `lalen/`, `masdiag/`, etc.) MUST be preserved — each namespace
serves a distinct client type with distinct authorization rules.

### II. Service-Object Architecture

Complex business logic MUST live in `app/services/`. Controllers MUST be thin: authenticate,
authorize, delegate to a service, serialize, respond. No business logic in controllers or models
beyond validations, associations, and scopes. Service objects inherit from `ApplicationService`
and return a result object (`success?`, `payload`, `error`). Max 100 lines per controller action;
max 50 lines per model method — extract service objects when limits are approached.

Each layer has a single, non-overlapping responsibility:

| Layer | Owns | MUST NOT contain |
|-------|------|-----------------|
| Controller | HTTP, params, response | Business logic, queries |
| Model | Validations, associations, scopes | Display logic, HTTP |
| Service | Business logic, orchestration, transactions | HTTP, display logic |
| Query | Complex database queries, aggregations | Business logic |
| Presenter | View formatting, badges, display | Business logic, queries |
| Policy | Authorization rules | Business logic |
| Job | Async processing | HTTP, display logic |
| Form | Complex form handling | Persistence logic |
| Mailer | Email composition | Business logic |

### III. Test-First (NON-NEGOTIABLE)

RSpec specs MUST be written before implementation code. The RED-GREEN-REFACTOR cycle is strictly
enforced. Factories (FactoryBot) are the only permitted test data mechanism — no fixtures.
Request specs use `http_auth_header` for authenticated calls. Background jobs, serializers, and
service objects each require their own spec. No PR merges without passing `bundle exec rspec`.

Each layer has a designated test type: models → unit; services → unit; controllers → request
(integration); policies → unit; query objects → unit; jobs → unit.

### IV. Security & Secrets Discipline

Credentials MUST be stored in Rails credentials (`bin/rails credentials:edit`), never in source
files, `.env` committed to git, or hardcoded strings. Lockbox field-level encryption is used for
sensitive model attributes. Every request authenticates via HTTP Basic Auth against `ApiAccount`
(bcrypt). Namespace-level authorization concerns (`MasdiagCheck`, `LalenCheck`, `NumeCheck`) MUST
be applied to their respective namespaces. No secrets, API keys, or tokens appear in logs or
serializer output.

### V. Multi-Tenancy Integrity

Institution isolation is non-negotiable. Every data-access path MUST scope records to the
authenticated account's institution. `institution_id == 1` is reserved for internal Masdiag
operations and is enforced by `MasdiagCheck`. Validation contexts (`:v1`, `:fv1`, `:lalen`)
MUST be used when a model's rules differ per namespace — never branch on namespace inside model
methods.

### VI. Layered Architecture & Abstraction Thresholds

Code MUST be placed in the correct layer per the decision tree below. Abstraction is introduced
only when a concrete threshold is crossed — premature abstraction is itself a violation.

**Where does new code go?**

- View/display formatting → Presenter (`app/presenters/`)
- Complex business logic → Service Object (`app/services/`)
- Complex database query (3+ joins, aggregations, reports) → Query Object (`app/queries/`)
- Shared behavior across 3+ models → Concern (`app/models/concerns/`)
- Authorization logic → Pundit Policy (`app/policies/`)
- Reusable UI with logic → (N/A — API-only project)
- Async/background work → Job (`app/jobs/`)
- Multi-model or wizard form → Form Object (`app/forms/`)
- Transactional email → Mailer (`app/mailers/`)
- HTTP request/response only → Controller (`app/controllers/`)

**Abstraction thresholds (MUST trigger extraction):**

| Signal | Required action |
|--------|----------------|
| Controller action > 15 lines | Extract to service object |
| Model file > 300 lines | Extract concerns or service |
| Same code in 3+ places | Extract to concern or service |
| Query joins 3+ tables | Extract to query object |
| Form spans multiple models | Extract to form object |
| Complex conditionals for authorization | Extract to Pundit policy |

**MUST NOT abstract when:**
- Logic is simple CRUD under 10 lines — keep in controller
- Code is used only once — inline it
- Query has 1–2 conditions — use a model scope
- Formatting is trivial — use a helper method

## Security & Multi-Tenancy Standards

Composite primary keys are used on select models — ActiveRecord finders MUST account for this.
Patient deduplication by PESEL (Polish national ID) is handled exclusively in `V1::SampleCreator`
and MUST NOT be duplicated elsewhere. Measurement status codes 1–7 represent workflow stages and
MUST NOT be altered without a documented migration plan. The `app/lib/` directory is autoloaded
and is the canonical location for shared constants (`V1::Common`).

Active Storage uses MinIO (S3-compatible, self-hosted) in production and disk adapter in
development/test. File content stored via `OnlineFile` MUST be Lockbox-encrypted. Sentry/GlitchTip
error capture is production-only — do not add Sentry calls in test or development code paths.

## Canonical Directory Structure

```
app/
├── controllers/
│   └── concerns/        # Shared controller behavior (auth, namespace checks)
├── forms/               # Form objects (multi-model, wizard forms)
├── jobs/                # Background jobs (Solid Queue)
├── mailers/             # Action Mailer classes
├── models/
│   └── concerns/        # Shared model behavior
├── policies/            # Pundit authorization
├── presenters/          # View formatting / display logic
├── queries/             # Complex query objects
├── resources/           # Alba serializers (*Resource)
└── services/            # Business logic service objects
    └── application_service.rb
app/lib/                 # Autoloaded shared constants (V1::Common, etc.)
```

New directories MUST NOT be added without a constitution amendment.

## Anti-Patterns (Prohibited)

The following patterns are explicitly prohibited and MUST be flagged in code review:

| Anti-Pattern | Problem | Required fix |
|--------------|---------|-------------|
| God Model (> 500 lines) | Unmanageable complexity | Extract services/concerns |
| Fat Controller (logic > 15 lines) | Violates Principle II | Move to service object |
| Callback Hell | Hidden side effects | Use service objects explicitly |
| N+1 Queries | Performance degradation | Use `.includes()` or query objects |
| Unscoped Cross-Tenant Query | Data leak | Scope through institution |
| Stringly Typed constants | Fragile, unrefactorable | Use `V1::Common` constants or enums |
| Premature Abstraction | Unnecessary complexity | Keep inline until threshold crossed |
| Business Logic in Serializer | Violates layer separation | Move to service or model |

## Development Workflow

1. Create a feature branch via `/speckit-git-feature` before any implementation.
2. Write a spec (`/speckit-specify`) before writing code.
3. Run `bundle exec rspec` locally before every commit; CI gates on green tests.
4. Solid Queue (not Sidekiq) handles background jobs. Jobs MUST be idempotent and use
   `retry_on StandardError, wait: :exponentially_longer, attempts: 5`.
5. Serialization uses Alba — `app/resources/*Resource`. JBuilder and AMS are prohibited.
6. Database migrations MUST be reversible. Run `db:migrate` for both development and test
   environments after schema changes.
7. Use `json_response` helper in controllers; never render JSON inline.
8. All PRs MUST pass the Constitution Check gates in the implementation plan before review.

## Governance

This constitution supersedes all conflicting practices in the codebase. Amendments require:
1. A documented rationale explaining the need for change.
2. An updated version number following semantic versioning (MAJOR.MINOR.PATCH).
3. Propagation to all affected templates under `.specify/templates/`.
4. A commit message of the form: `docs: amend constitution to vX.Y.Z (summary of change)`.

All implementation plans MUST include a Constitution Check section that explicitly verifies
compliance with principles I–VI before Phase 0 research begins. Non-compliance MUST be justified
in the Complexity Tracking table of the plan.

Versioning policy: MAJOR for principle removals or redefinitions; MINOR for new principles or
material guidance additions; PATCH for clarifications and wording improvements.

**Version**: 1.1.0 | **Ratified**: 2023-03-02 | **Last Amended**: 2026-05-26
