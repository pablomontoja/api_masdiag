# Implementation Plan: Project and User Attribute Translation

**Branch**: `012-project-name-translation` | **Date**: 2026-09-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-project-name-translation/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Extend the Mobility (`key_value` backend) translation pattern already proven on `Analyte#NameInReport` to `Project#Name`: Polish stays in the native `Projects.Name` column (writes under `:pl` bypass the translation backend via an overridden setter), English lives in the shared `mobility_string_translations` table. A one-time, idempotent data migration backfills an English translation for all 47 existing Projects, sourcing the value from `Projects.eng_name` where that column is verifiably an actual English name, and from a hand-curated mapping (embedded in the migration file for reviewability) everywhere else. Separately, `User` gains the same `translates` declaration for `FirstName`, `LastName`, and `Description` — model-only, no backfill migration, no behavior change under the default locale.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.0.5 (per `.ruby-version` / `Gemfile`)

**Primary Dependencies**: `mobility` gem `~> 1.3.2` (already installed, configured in `config/initializers/mobility.rb` with `key_value` backend, `active_record`, `reader`, `writer`, `backend_reader`, `query`, `cache`, `presence` plugins, global `default nil`)

**Storage**: MySQL — shared `LabSample` database. Target tables: `Projects` (existing, no schema change), `Users` (existing, no schema change), `mobility_string_translations` (existing, generic/polymorphic, already used by `Analyte`, no schema change)

**Testing**: RSpec + FactoryBot (`bundle exec rspec spec/models/project_spec.rb`, `bundle exec rspec spec/models/user_spec.rb`); no fixtures

**Target Platform**: Rails 8 API server, Linux

**Project Type**: Single Rails API application (existing monolith, no new project structure)

**Performance Goals**: N/A — one-time migration over 47 rows and a handful of new model methods; no throughput target

**Constraints**: MUST NOT alter the `Projects` or `Users` table schema (shared LabSample database — schema changes require explicit user confirmation per repository policy, and none is needed here since `mobility_string_translations` already exists generically). MUST NOT change default-locale (`:pl`) read/write behavior for any existing caller.

**Scale/Scope**: 47 `Project` rows backfilled once; `User` model declaration only (no row-level change, table has many rows but none are touched in this iteration)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Rails Conventions Over Configuration | `translates` declaration follows the exact existing `Analyte` convention; no new configuration pattern introduced | PASS |
| II. Service-Object Architecture | No controller or business-orchestration logic involved — this is model-declaration + a data migration. No service object needed (migration is the correct location for one-time data backfill, not business logic) | PASS (N/A) |
| III. Test-First (NON-NEGOTIABLE) | New RSpec model specs for `Project` (mirroring `spec/models/analyte_spec.rb`) MUST be written before the model change; `User` spec additions MUST be written before the `translates` declaration | PASS — planned in Phase 1 / tasks |
| IV. Security & Secrets Discipline | No credentials or secrets involved; no encrypted fields touched | PASS (N/A) |
| V. Multi-Tenancy Integrity | `Project` and `User` are not institution-scoped, shared reference/lookup data (same as `Analyte`) — no tenant-scoping concern | PASS (N/A) |
| VI. Layered Architecture & Abstraction Thresholds | Change is confined to `app/models/project.rb`, `app/models/user.rb`, and one migration file — no new abstraction, no threshold crossed | PASS |
| Shared LabSample DB schema rule (CLAUDE.md) | No schema change (no new/altered/dropped column, index, or constraint) — `mobility_string_translations` is pre-existing and generic. Confirmed no migration adds/alters/drops anything on `Projects` or `Users` | PASS |

No violations. Complexity Tracking table not needed.

## Project Structure

### Documentation (this feature)

```text
specs/012-project-name-translation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output — empty/omitted, see rationale below
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
app/
└── models/
    ├── analyte.rb        # Existing reference pattern (unchanged)
    ├── project.rb        # MODIFIED — add `extend Mobility`, `translates :Name`, overridden setter
    └── user.rb            # MODIFIED — add `extend Mobility`, `translates :FirstName, :LastName, :Description`, overridden setters

db/
└── migrate/
    └── <timestamp>_backfill_project_english_names.rb   # NEW — one-time idempotent data migration (Project only)

spec/
├── models/
│   ├── analyte_spec.rb    # Existing reference pattern (unchanged)
│   ├── project_spec.rb    # NEW — mirrors analyte_spec.rb structure for Name translation
│   └── user_spec.rb        # MODIFIED/NEW — covers translatable declaration + no-regression checks
└── factories/
    └── project_factory.rb  # Unchanged (existing eng_name attribute stays as-is)
```

**Structure Decision**: Single existing Rails application, no new directories. Changes land in the conventional `app/models/`, `db/migrate/`, and `spec/models/` locations already used by the `Analyte` precedent. No controllers, services, jobs, or serializers are touched — this feature is model + migration only, consistent with Constitution Principle VI (no abstraction beyond what's needed).

## Complexity Tracking

*No violations — table omitted.*
