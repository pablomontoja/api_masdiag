# Implementation Plan: Toxo Sample Email Notification System

**Branch**: `005-toxo-notification-system` | **Date**: 2026-07-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/005-toxo-notification-system/spec.md`

## Summary

Deliver six sample-lifecycle email notifications (A order confirmation, B sample accepted, C registration reminder, D final registration reminder, E sample rejected, F result available) and, in the process, **unify the laboratory notification system**. Rather than adding Toxo-specific trigger endpoints, LabSample calls **one event endpoint per lifecycle event under the `masdiag` namespace** (e.g. `POST /masdiag/sample_accepted`). api_masdiag — not LabSample — decides which email template to render for that event, choosing between the **regular laboratory template** and the **Toxo template** based on the sample's owning institution. The set of Toxo institutions is a hard-coded id array in the codebase, mirroring `V1::Common::LALEN_INSTITUTION_IDS`.

Server-side, each endpoint enqueues a per-event job that delegates to a **dispatcher** service. The dispatcher determines the notification "family" (lab vs. toxo) from the sample's institution, resolves the recipient, enforces idempotency via the existing polymorphic `Note` model, renders the correct template, delivers asynchronously, and writes the existing `ResultSendingEvent`/`Fileable` audit record. Where the existing laboratory notification set lacks an equivalent template for an event (registration reminders C and D have no lab analog), the missing template is created per the Toxo notification requirements so the unified system is complete. The time-based event D is additionally evaluated by a daily recurring Solid Queue job. Event A attaches a Prawn PDF summary of the registration form.

## Technical Context

**Language/Version**: Ruby 3.1.2 (repo pinned), Rails 7 (API-only)

**Primary Dependencies**: Action Mailer, Solid Queue (background + recurring), Prawn / prawn-table (PDF), `business_time` 0.13.0 (working-day math), Pundit (toxo portal namespace only), existing `Note`, `ResultSendingEvent`/`Fileable`, `OnlineFile`, `ReservedSampleCode`, `Institution`, `Contractor` models

**Storage**: MySQL (existing legacy schema — `Samples`, `Patients`, `ReservedSampleCodes`, `Measurements`, `notes`, `Contractors`, `Institutions`); no new tables (idempotency via existing `notes` table)

**Testing**: RSpec + FactoryBot (constitution III); mailer/job/service/request specs each separate; `http_auth_header` for `masdiag` request specs; Bearer-token session for the one `toxo` portal touchpoint (event A)

**Target Platform**: Linux server (API-only Rails app; HTTP Basic auth on `masdiag`, Bearer token on `toxo`)

**Project Type**: Web service (single Rails API project) — existing directory layout, no new top-level structure

**Performance Goals**: State-triggered notifications enqueued within seconds of the trigger; endpoints return `200` without waiting for delivery (SC-004)

**Constraints**: At-most-one email per sample + kind (DB-enforced via `Note` uniqueness); **template selection is server-side only — LabSample never chooses lab-vs-toxo**; toxo institution ids hard-coded as a code constant; reminders resolve recipient via code → RSC → `institution.email_for_notifications` (never the virtual patient's `ContractorId`); 7 working days from `AcceptanceDate` excluding weekends + Polish holidays; no email for physical-only procedures; existing lab notification behavior for non-toxo samples MUST be preserved

**Scale/Scope**: Six events; new unified `masdiag` event endpoints; one dispatcher + resolver + finder service; per-event jobs; two email template families (lab + toxo) with the toxo family fully built and the two missing lab-analog templates (C, D) created; one PDF class; `business_time` initializer; `Note` allowed-keys + `config/recurring.yml` additions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Rails Conventions Over Configuration | PASS | Event endpoints consolidated in the `masdiag` namespace (internal ops), preserving namespace separation; mailers/jobs/services/PDF in canonical dirs |
| II. Service-Object Architecture | PASS | Controllers thin (authenticate → `MasdiagCheck` → enqueue → `json_response`); template selection, recipient resolution, idempotency, audit all in service objects; mailers compose email only. This replaces existing ad-hoc branching (e.g. `SendCancellationNotificationsJob`) with an explicit dispatcher |
| III. Test-First (NON-NEGOTIABLE) | PASS | RSpec-first for every endpoint, job, service, mailer; FactoryBot only |
| IV. Security & Secrets Discipline | PASS | No new secrets; `MasdiagCheck` (institution_id == 1) gates all event endpoints; email bodies carry only non-sensitive fields (spec §4) |
| V. Multi-Tenancy Integrity | PASS | Template family + reminder recipient derived from the sample's institution (through code → RSC → institution); toxo id set is an explicit constant, not a scattered literal |
| VI. Layered Architecture & Abstraction Thresholds | PASS | Async → Job; branching/business logic → Service (dispatcher); email → Mailer; PDF → `app/pdfs/`; constant → `app/lib`. The dispatcher is justified abstraction: template-selection logic already exists in 3+ places (cancellation/acceptance/result jobs) — constitution's "same code in 3+ places → extract" |

**Result**: PASS — no violations; Complexity Tracking not required.

Workflow gates: jobs idempotent + `retry_on StandardError, wait: :exponentially_longer, attempts: 5`; recurring job in `config/recurring.yml`; controllers use `json_response`; no migrations needed.

### Scope guardrail (important)

Unifying the notification system is broad. To bound risk, this feature:
- **Adds** the new `masdiag` event endpoints and the dispatcher, and routes **toxo-institution samples** to new toxo templates.
- For **non-toxo samples**, the dispatcher delegates to the **existing** lab mailers/behavior — it does not rewrite them — **for the four events that have a lab analog (A, B, E, F)**. The two registration reminders (**C, D**) have **no lab counterpart**: for a non-toxo institution the dispatcher skips them with a recorded reason (only toxo institutions receive C/D today). Existing `masdiag_mailer` endpoints remain callable during transition (deprecate later, out of scope here).
- Per the user's standing instruction, existing controllers are not modified beyond adding the new `masdiag` routes/actions and the single event-A enqueue hook in the portal registrations controller — no behavioral edits to existing lab mailer internals.

## Project Structure

### Documentation (this feature)

```text
specs/005-toxo-notification-system/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── masdiag-event-endpoints.md      # unified LabSample-facing event endpoints
│   └── toxo-order-confirmation.md      # portal-side event A hook
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── masdiag/
│   │   └── notifications_controller.rb      # (new) unified event endpoints: sample_accepted, registration_reminder, sample_rejected, result_available (+ optional order_confirmation)
│   └── toxo/
│       └── samples/
│           └── registrations_controller.rb  # (edit) enqueue order_confirmation event after successful create
├── services/
│   └── notifications/                        # (new) unified dispatch layer (NOT toxo-only — this is the system-wide router)
│       ├── event_dispatcher.rb               # entry: given (event, sample) → pick family (lab|toxo) by institution → delegate
│       ├── template_resolver.rb              # institution id → :toxo (V1::Common::TOXO_INSTITUTION_IDS) | :lab | other existing families
│       ├── recipient_resolver.rb             # registered → contractor email; reminders → code→RSC→institution.email_for_notifications
│       ├── sender.rb                          # idempotency guard (Note) + deliver + audit (ResultSendingEvent/Fileable) + mark Note
│       └── registration_reminders_finder.rb  # delivered + virtual + 7 business days since AcceptanceDate
├── mailers/
│   └── toxo/
│       └── sample_notification_mailer.rb     # (new) toxo template family: 6 actions
├── views/
│   └── mailers/
│       └── toxo/
│           └── sample_notification_mailer/   # (new) 6 Polish HTML views (incl. C & D — the missing lab-analog templates, built to toxo spec)
├── jobs/
│   └── notifications/                        # (new) one job per event → EventDispatcher
│       ├── order_confirmation_job.rb
│       ├── sample_accepted_job.rb
│       ├── registration_reminder_job.rb
│       ├── sample_rejected_job.rb
│       ├── result_available_job.rb
│       └── registration_reminder_final_job.rb   # recurring sweep (event D)
├── pdfs/
│   └── toxo/
│       └── order_confirmation_pdf.rb          # (new) Prawn registration-form summary (mirrors RegistrationConfirmationThreeOmdPdf)
├── models/
│   └── note.rb                                # (edit) add notification keys
└── lib/
    └── v1/
        └── common.rb                          # (edit) add TOXO_INSTITUTION_IDS = [...]; notification kind keys / portal URL

config/
├── recurring.yml                              # (edit) daily registration_reminder_final sweep
└── initializers/
    └── business_time.rb                        # (new) Polish holidays (fixed + movable)

spec/                                           # RSpec mirrors the above
```

**Structure Decision**: Single Rails API project. The dispatch layer lives in `app/services/notifications/` (system-wide, not toxo-scoped) because its job is precisely to route between families; the **toxo** family (mailer, views, PDF) is namespaced under `Toxo::`. Event endpoints consolidate in `Masdiag::NotificationsController`. No new top-level directories — constitution "Canonical Directory Structure" preserved. `V1::Common` is the canonical home for the `TOXO_INSTITUTION_IDS` constant (alongside `LALEN_INSTITUTION_IDS`).

## Complexity Tracking

No constitution violations — table intentionally empty.

## Phase 0 — Research

See [research.md](./research.md) — 10 design decisions grounded in verified codebase patterns (the existing per-institution template branching in `SendCancellationNotificationsJob`, the `LALEN_INSTITUTION_IDS` constant, the `after_sample_registration` template branch, `Note` idempotency, `business_time`, Prawn PDF). No `NEEDS CLARIFICATION` remain.

## Phase 1 — Design & Contracts

- [data-model.md](./data-model.md) — entities + notification-kind key catalog + the lab-vs-toxo template mapping (which events already have lab templates, which are newly built).
- [contracts/](./contracts/) — unified `masdiag` event endpoints + portal event-A hook.
- [quickstart.md](./quickstart.md) — trigger each event, verify template selection by institution, verify idempotency and audit.

Post-design Constitution re-check: **PASS** (no new directories, no new secrets, no cross-tenant access, thin controllers, ad-hoc branching replaced by an explicit service).
