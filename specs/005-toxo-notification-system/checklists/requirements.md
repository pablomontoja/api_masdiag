# Specification Quality Checklist: Toxo Sample Email Notification System

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-17
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Six notification kinds (A–F) each map to a functional requirement (FR-003…FR-008) and a prioritized user story (US1–US6).
- "Namespace only in toxo/masdiag/masdiag_mailer" and "add endpoints only where existing ones can't carry the event" are encoded as FR-013.
- The time-based `registration_reminder_final` is captured as a recurring, server-side-detected event (FR-012, US5) distinct from the state-triggered events.
- Idempotency (at most one email per sample + kind) and audit logging are first-class requirements (FR-016, FR-017) driven by the source document's "Idempotencja" note.
- Two source-document ambiguities are resolved via Assumptions rather than [NEEDS CLARIFICATION] markers: (1) exact order-confirmation email wording, (2) whether result re-publication re-notifies. Both have reasonable defaults and do not change scope.
- Clarification session 2026-07-17 resolved the four highest-impact unknowns and grounded them in verified codebase facts:
  - Reminder recipient resolution: sample code → reserved sample code → institution → `institution.email_for_notifications`; the virtual patient's `ContractorId` is explicitly NOT used (FR-002).
  - "Delivered but unregistered" is derived from an existing `Sample` (`AcceptanceDate` set) whose patient is `IsVirtual == true`; 7 working days counted from `AcceptanceDate` (FR-012, FR-019).
  - Idempotency enforced via the existing polymorphic `Note` model keyed per notification kind on the Sample subject; `ResultSendingEvent`/`Fileable` still written for audit (FR-016, FR-017).
  - Working-day math uses the `business_time` gem (already in the Gemfile) with Polish holidays configured (FR-019).
- Items marked incomplete require spec updates before `/speckit-plan`.
