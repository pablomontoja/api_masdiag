# Phase 0 — Research: Toxo Sample Email Notification System (unified dispatch)

Revised per the user's direction (2026-07-18): endpoints unified under the `masdiag` namespace, api_masdiag chooses the email template family (lab vs. toxo) server-side, toxo institutions held as a code constant. Decisions are grounded in verified codebase patterns.

---

## D1. Endpoint placement & event model

- **Decision**: One endpoint per lifecycle event under `namespace :masdiag`, e.g. `POST /masdiag/sample_accepted`, `/masdiag/registration_reminder`, `/masdiag/sample_rejected`, `/masdiag/result_available`. Each takes a sample identifier (id or code) and enqueues a per-event job. LabSample calls the same endpoint regardless of whether the sample is toxo or a regular lab sample.
- **Rationale**: The user requires LabSample to be agnostic about template choice; the event ("sample accepted") is the stable contract, the template is an internal detail. `masdiag` namespace already exists for internal Masdiag operations, is gated by `MasdiagCheck` (institution_id == 1), and LabSample already authenticates there.
- **Alternatives considered**: per-client endpoints in `masdiag_mailer` (rejected by user — pushes template decision to LabSample); a single generic `/masdiag/sample_event` with a `kind` param (viable, but explicit per-event routes are clearer and match the existing style of `masdiag`/`masdiag_mailer`).

## D2. Server-side template selection (the core of the unification)

- **Decision**: A `Notifications::EventDispatcher` service receives `(event, sample)` and asks `Notifications::TemplateResolver` for the template **family** from the sample's owning institution: toxo family if the institution is in `V1::Common::TOXO_INSTITUTION_IDS`, otherwise the existing lab family (and existing sub-branches). The dispatcher then routes to the toxo mailer or the existing lab mailer accordingly.
- **Concrete precedent**: `MasdiagMailer::SendCancellationNotificationsJob` already branches template choice on institution / RSC-box origin across 8+ `if` clauses; `after_sample_registration` in `MasdiagMailer::EmailsController` already picks `ThreeMethylDopaMailer` vs `IndMailer` by project. This feature consolidates that scattered logic into one explicit resolver (constitution: "same code in 3+ places → extract to service").
- **Rationale**: Centralizes an existing, duplicated concern; makes "which template for this institution/event" answerable in one place; keeps LabSample dumb.
- **Alternatives considered**: keep branching inside each mailer/job (rejected — that's the status quo the user wants ordered).

## D3. Toxo institution set as a code constant

- **Decision**: `V1::Common::TOXO_INSTITUTION_IDS = [...]` (exact ids to be filled from the toxo pool config), placed beside the existing `V1::Common::LALEN_INSTITUTION_IDS = [83, 85, 89, 93, 95]`.
- **Rationale**: The user explicitly chose an in-code array; `V1::Common` (`app/lib`) is the constitution-designated home for such constants and already holds `LALEN_INSTITUTION_IDS`. Avoids stringly/scattered literals (constitution anti-pattern).
- **Alternatives considered**: DB flag on `Institutions` (rejected by user for now — array in code); could be migrated to a column later without changing the resolver's interface.

## D4. Mailer structure (toxo family)

- **Decision**: `Toxo::SampleNotificationMailer < ApplicationMailer` with six actions and Polish HTML views under `app/views/mailers/toxo/sample_notification_mailer/`. Uses `default template_path => "mailers/#{self.name.underscore}"` and inherits `ApplicationMailer` sender/layout/delivery-job defaults.
- **Rationale**: Matches existing `MasdiagMailer::*` conventions; one class for the six related emails.
- **Alternatives considered**: reuse the existing lab mailers with toxo view variants (rejected — cleaner to keep the toxo family self-contained; the dispatcher selects between families).

## D5. Missing lab-analog templates → build to toxo spec

- **Decision**: Map events to existing lab templates and identify gaps:
  | Event | Existing lab analog | Action |
  |-------|--------------------|--------|
  | A order confirmation | `IndMailer#after_sample_registration` / `ThreeMethylDopaMailer` | build toxo variant (+ PDF) |
  | B sample accepted | `SendAcceptanceNotificationsMailer` | build toxo variant |
  | E sample rejected | `SendCancellationNotificationsMailer` | build toxo variant |
  | F result available | `ContractorResultNotificationMailer` | build toxo variant |
  | C registration reminder | **none** | **new template**, built to toxo spec |
  | D final registration reminder | `SendNotificationAfterDelayedRegMailer` is *late-registration*, not a pre-registration reminder → **not equivalent** | **new template**, built to toxo spec |
- **Rationale**: The user asked to create missing equivalents per toxo requirements. C and D (pre-registration reminders to the institution) have no lab counterpart; they are authored fresh from spec §C/§D. The others have lab counterparts, so the toxo family mirrors their shape while using the toxo wording/recipient rules.
- **Alternatives considered**: treat `SendNotificationAfterDelayedReg` as D's analog (rejected — it notifies after a *delayed registration already happened*, whereas D warns an *unregistered* sample will be returned; different semantics/recipient).

## D6. Idempotency (`Note` model)

- **Decision**: Guard every send with the existing polymorphic `Note` (subject = `Sample`, `key` = per-event key); create the Note after a successful send; the model's `uniqueness: { scope: [:subject_type, :key] }` enforces at-most-once. Keys apply regardless of family, so a sample gets one email per event whichever template was chosen.
- **Concrete precedent**: `LalenIncomingSamplesJob` (`Note.where(key:…, subject_type:"Sample")` to exclude already-sent; `Note.create(key:…, subject: smp)` after send).
- **Required edit**: add keys to `Note#available_keys` — `sample-accepted-email`, `registration-reminder-email`, `registration-reminder-final-email`, `sample-rejected-email`, `result-available-email`, `order-confirmation-email` (family-neutral keys; the resolved family is recorded in the Note `description`).
- **Alternatives considered**: family-specific keys (rejected — the guarantee is per event, not per template).

## D7. Recipient resolution

- **Decision**: `Notifications::RecipientResolver`: registered events (A/B/E/F) → ordering party's contractor email (honoring `are_notifications_enabled`); reminders (C/D) → `sample.Code` → `ReservedSampleCode` → `Institution.email_for_notifications`. Virtual patient's `ContractorId` MUST NOT resolve the institution for reminders. Blank/disabled → skip with recorded reason, never raise (FR-018).
- **Rationale**: Verified fields (`Institution#email_for_notifications`, `Contractor#email`/`are_notifications_enabled`, `Patient#IsVirtual`). Same resolver serves both families.
- **Alternatives considered**: LabSample supplies email (rejected earlier in clarify).

## D8. "Delivered but unregistered" + final reminder (D)

- **Decision**: A delivered sample = `Sample` with `AcceptanceDate` present, patient still virtual (`IsVirtual == true`, placeholder "PACJENT/TOXO") and/or `IsWrongRegistration`. `RegistrationRemindersFinder` selects toxo-institution samples that are delivered, still unregistered, ≥7 business days past `AcceptanceDate`, and lack the final-reminder Note.
- **Concrete precedent**: `Toxo::SamplePolicy::Scope` (PACJENT/TOXO + IsWrongRegistration as the unregistered set), `LalenIncomingSamplesJob` (AcceptanceDate + Note-exclusion sweep), `DelayedSamplesJob`+`DelayedSamplesFinder` (finder-service + recurring-job split).
- **Alternatives considered**: new state column (rejected — existing fields suffice; shared legacy table).

## D9. Working-day / holiday calendar

- **Decision**: `business_time` (0.13.0, already present) + `config/initializers/business_time.rb` configuring Polish fixed + movable (Easter-based) holidays; deadline = `AcceptanceDate.to_date + 7.business_days`.
- **Alternatives considered**: hand-rolled weekend math (rejected — holidays required); app-managed list (rejected — movable feasts drift).

## D10. Controller/job/service split & event-A hook

- **Decision**: `Masdiag::NotificationsController` action = `MasdiagCheck` → validate sample id/code → enqueue `Notifications::<Event>Job` → `json_response("OK")`. Job = `retry_on StandardError … attempts: 5` → `EventDispatcher`. Event A additionally enqueued from `Toxo::Samples::RegistrationsController#create` on success (portal/Bearer context), because there is no LabSample "registration submitted" event — it originates in the portal.
- **Rationale**: constitution II/VI; matches existing enqueue-and-OK controllers. Order confirmation for a *toxo* registration naturally fires from the portal; a `masdiag` endpoint may also be exposed for lab-originated confirmations if needed, but the portal hook covers event A for toxo.
- **Alternatives considered**: fire A only from a `masdiag` endpoint (rejected — the registration event happens in the portal app, not LabSample).

## Open items deferred to implementation (non-blocking)

- Exact `TOXO_INSTITUTION_IDS` values (fill from the toxo pool config at implementation).
- Exact Polish body wording for A (spec Assumption: adjustable; start from source-plan placeholder).
- Whether/when to deprecate the old `masdiag_mailer` per-event endpoints (out of scope; they remain during transition).
