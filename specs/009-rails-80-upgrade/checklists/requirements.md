# Specification Quality Checklist: Rails 7.2 → 8.0 Upgrade

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-18
**Feature**: [spec.md](../spec.md)

## Content Quality

- [X] No implementation details (languages, frameworks, APIs)
- [X] Focused on user value and business needs
- [X] Written for non-technical stakeholders
- [X] All mandatory sections completed

## Requirement Completeness

- [X] No [NEEDS CLARIFICATION] markers remain
- [X] Requirements are testable and unambiguous
- [X] Success criteria are measurable
- [X] Success criteria are technology-agnostic (no implementation details)
- [X] All acceptance scenarios are defined
- [X] Edge cases are identified
- [X] Scope is clearly bounded
- [X] Dependencies and assumptions identified

## Feature Readiness

- [X] All functional requirements have clear acceptance criteria
- [X] User scenarios cover primary flows
- [X] Feature meets measurable outcomes defined in Success Criteria
- [X] No implementation details leak into specification

## Notes

### On the "no implementation details" criterion

This is an infrastructure-upgrade spec, so the boundary sits differently than it would for a
product feature. The upgrade **target** — framework 7.2.3 → 8.0 — is the subject of the request,
not a leaked implementation choice, and the same applied to specs 007 and 008.

Everything below that line is expressed by behaviour rather than mechanism. The spec deliberately
does not name commands, file paths, configuration keys, or gem-resolution flags; those belong in
`plan.md` and `quickstart.md`. Two blocking gems are named because they are *facts about the
current state that gate the work*, not choices — and FR-003 states the decision must be recorded
without prescribing which of the three exits to take.

### Verification performed before writing

Ten of the guide's breaking-change items were scanned against the codebase and found already clean
(recorded in the spec's Context table). This keeps the plan from budgeting work that specs 007 and
008 already completed — most notably the enum migration, which the source guide calls the most
common failure point.

### Traceability

Every SC-### cites the FR-### it measures. All 25 functional requirements are cited by at least one
success criterion.

### Counts used in success criteria

Verified against the repository at the time of writing: 11 namespaces, 98 spec files, 13 enum
declarations across 8 models, 6 regular-expression sites, 2 configured locales, 3 non-production
environments, 25 parameter-handling call sites.

The namespace count is taken from `config/routes.rb`, not from the table in `CLAUDE.md`. That table
lists nine and omits `toxo` and `diagnostyka_precyzyjna`; the routes are authoritative, and the
project documentation is worth correcting separately.

### Clarification session 2026-08-18

Five questions asked and integrated. Requirement count grew from 25 to 28 (FR-008a, FR-008b,
FR-009a) and success criteria from 17 to 19 (SC-013a, SC-013b), with FR-003, FR-005, FR-009 and
FR-018 rewritten from open decisions into settled ones.

Resolved:

1. **Annotation gem** — replace with the `annotaterb` fork; outright removal retained as fallback.
2. **Framework defaults** — the upgrade is not complete until 8.0 defaults are active; adopted as a
   separate verified step, so the suite and all namespaces are verified twice.
3. **Contract equivalence evidence** — the existing test suite with *unchanged assertions*, plus a
   per-namespace report that names thin-coverage namespaces rather than hiding them.
4. **Job admin dashboard** — must render, not merely respond. Surfaced during clarification: it is
   the app's only asset-serving surface, sets no asset config of its own, and therefore inherits
   exactly the framework defaults this upgrade changes.
5. **Patch target** — latest 8.0.x at implementation time, pinned exactly.

### Status

All items pass. Ready for `/speckit-plan`.
