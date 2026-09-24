# Specification Quality Checklist: Toxo Contractor Result Notifications Repair

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-09-24
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

- A "Background (as-is investigation)" section was added above the mandatory sections to capture the root-cause findings from code exploration (two separate notification pipelines, one-shot idempotency). This is investigative context, not a spec section proper, and does not replace or duplicate the mandatory sections.
- `/speckit-clarify` (session 2026-09-24) resolved three material ambiguities directly with the user: (1) the measurement table shows all measurements regardless of status, not only authorized ones; (2) the historical notification backlog is explicitly NOT recovered/backfilled — contractors retained portal access throughout the outage, so nothing is lost, and mass-sending old notifications risks flooding recipients; this eliminated the originally-drafted "backlog recovery" user story entirely and replaced it with a cutoff-gated eligibility story; (3) the email's PDF link reuses the same signed Active Storage URL the Toxo portal's `/results` page already renders directly (confirmed via code exploration of the separate `toxo` frontend app), avoiding any new proxy/auth mechanism.
- Remaining lower-impact judgment call resolved via documented Assumption rather than a clarification question: the cutoff date is a single global setting, not per-institution/per-contractor — consistent with how the user described it, and low risk if wrong (easy to revisit in planning).
- Post-implementation revision (2026-09-24): the user judged the `Notifications::ResultEligibility` service object plus `KeyValueDbStore` runtime-configurable storage over-engineered for a value meant to be set once at deploy time. FR-002 and FR-002a were revised — the cutoff is now `Notifications::ResultAvailableJob::CUTOFF_DATE`, a plain constant, with the eligibility check inlined into the job. spec.md, plan.md, research.md, data-model.md, contracts/, and tasks.md were all updated to match; the removed service, its spec, and the `KeyValueDbStore` accessor were deleted from the codebase.
