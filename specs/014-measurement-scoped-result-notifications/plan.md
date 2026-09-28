# Implementation Plan: Measurement-Scoped Result-Available Notifications

**Branch**: `014-measurement-scoped-result-notifications` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-measurement-scoped-result-notifications/spec.md`

## Summary

`Notifications::EventDispatcher.call(event: :result_available, sample:)` and the
`Notifications::Sender` idempotency layer (`Note` keyed on `subject_type: "Sample"`)
currently track "has result-available been sent" per **Sample**. Since
`Sample has_many :measurements`, only the first measurement authorized on a sample
ever triggers a notification — every later measurement on that same sample is
silently skipped forever. The fix moves this one event's trigger and idempotency
tracking to be **Measurement**-scoped throughout (`EventDispatcher`,
`Notifications::Sender`/`Note`, `Notifications::ResultAvailableJob`,
`Masdiag::NotificationsController#result_available`), while the Toxo email
content keeps rendering the full `sample.measurements` table on every send (plus
one new sentence identifying the triggering measurement), and the legacy
`:lab`-family dispatch path gets a companion fix so it doesn't start resending
already-delivered files now that its trigger can fire more than once per sample.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.0.5 (API-only)

**Primary Dependencies**: Solid Queue (background jobs), Action Mailer, MySQL via `mysql2`

**Storage**: Existing `LabSample` MySQL database — no schema change. `Note.subject_type`/`subject_id` are already generic polymorphic columns; `Note::KEYS_BY_SUBJECT` is an in-code Ruby constant, not a DB constraint, so adding `"result-available-email"` to the existing `"Measurement"` key list requires no migration.

**Testing**: RSpec + FactoryBot (no fixtures), per constitution Principle III

**Target Platform**: Linux server (existing Rails API deployment)

**Project Type**: Single Rails API-only application (existing `api_masdiag` codebase)

**Performance Goals**: N/A — this is a correctness fix to an existing low-volume notification path, no new performance surface

**Constraints**: LabSample (the external C# caller) does not yet call `POST /masdiag/result_available`, so this endpoint's request contract may change without any breaking impact on a live integration. All five other `Notifications::EventDispatcher` events remain Sample-scoped and untouched.

**Scale/Scope**: Touches 8 production files and 7 spec files, all within the existing `Notifications::*`/`Toxo::*`/`MasdiagMailer::*` notification subsystem — no new namespaces, models, or tables.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Rails Conventions Over Configuration | No new routes deviate from REST conventions beyond the existing `post "result_available/:id"` pattern (just changes which id). No new namespace. | PASS |
| II. Service-Object Architecture | All new logic lives in existing service objects (`Notifications::EventDispatcher`, `Notifications::Sender`) and a job (`Notifications::ResultAvailableJob`). Controller action stays a thin lookup + enqueue (~5 lines). No business logic added to models or controllers. | PASS |
| III. Test-First (NON-NEGOTIABLE) | Every production file change is paired with a spec file change per the TDD task breakdown in this plan; RED before GREEN throughout. | PASS |
| IV. Security & Secrets Discipline | No new credentials, no new auth surface — `MasdiagCheck` continues to gate the controller action unchanged. | PASS |
| V. Multi-Tenancy Integrity | `TemplateResolver`/`RecipientResolver` remain untouched and continue to scope by the sample's institution/contractor via `measurement.sample`. | PASS |
| VI. Layered Architecture & Abstraction Thresholds | No generic/polymorphic `subject:` abstraction introduced — `EventDispatcher`/`Sender` gain one additional optional keyword (`measurement:`) alongside the existing `sample:`, which is the minimal change for a single-event concern, consistent with "MUST NOT abstract when... used only once." No controller action exceeds 15 lines. | PASS |

No violations — Complexity Tracking table not needed.

## Project Structure

### Documentation (this feature)

```text
specs/014-measurement-scoped-result-notifications/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
│   └── service-interfaces.md
└── tasks.md              # Phase 2 output (/speckit-tasks command — NOT created by /speckit-plan)
```

### Source Code (repository root)

Existing single Rails API application — no new top-level structure. This feature
only modifies files within the existing `Notifications::*` subsystem:

```text
app/
├── controllers/masdiag/notifications_controller.rb   # MODIFIED — result_available action keyed on measurement_id
├── jobs/notifications/result_available_job.rb         # MODIFIED — perform(measurement_id), single-measurement eligibility
├── mailers/toxo/sample_notification_mailer.rb          # MODIFIED — result_available(sample, measurement)
├── models/note.rb                                      # MODIFIED — add "result-available-email" to Measurement key list
├── services/notifications/event_dispatcher.rb          # MODIFIED — accept measurement:, dispatch_lab unsent-files guard
├── services/notifications/sender.rb                    # MODIFIED — accept measurement:, generalize idempotency subject
└── views/mailers/toxo/sample_notification_mailer/
    └── result_available.html.erb                       # MODIFIED — add triggering-measurement sentence

config/routes.rb                                         # MODIFIED — result_available/:measurement_id

spec/
├── controllers/ (n/a — request specs used per constitution)
├── requests/masdiag/result_available_spec.rb            # MODIFIED
├── jobs/notifications/result_available_job_spec.rb      # MODIFIED
├── services/notifications/event_dispatcher_spec.rb      # MODIFIED
├── services/notifications/sender_spec.rb                # MODIFIED
├── mailers/toxo/sample_notification_mailer_spec.rb      # MODIFIED
└── models/note_spec.rb                                  # MODIFIED (or created if absent)
```

**Structure Decision**: No new directories or layers. Every change fits the
existing `Notifications::*` service/job structure and `Toxo::*` mailer — the
constitution's "MUST NOT abstract when used only once" rule directly supports
adding a single optional `measurement:` keyword to the two existing service
objects rather than introducing a new polymorphic dispatch layer.

## Complexity Tracking

*No violations — table not needed.*
