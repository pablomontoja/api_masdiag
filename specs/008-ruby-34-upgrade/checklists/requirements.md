# Specification Quality Checklist: Ruby 3.4 Upgrade

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-17
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

### This spec is unusual: the upgrade was measured before it was specified

Most specs describe intended work. This one describes work whose feasibility and cost are
already **empirically known**, because a full trial ran on Ruby 3.4.9 in a sandbox before
the spec was written:

| Measured | Result |
|----------|--------|
| Dependency graph resolution | ✅ clean, including the git-sourced gem |
| Native gem compilation (27 entries) | ✅ all built |
| Full test suite | ✅ **755 examples, 0 failures** — matches the 3.3.7 baseline |
| Deprecation warnings | **0** |
| Application code changes required | **none** |
| Dependency declarations required | **one** (`observer`) |

The trial was discarded and nothing was applied to the project. It is evidence for sizing,
not completed work — FR-002 still mandates a fresh scan at execution time, because the
conclusion could change if dependencies move in the interim.

### Why this is much smaller than spec 007

Spec 007 handled `csv` and `base64` explicitly to reduce this feature's scope, and that
paid off — only the third case (`observer`) remained. The blocker chain is now closed:

- `csv` — 6 files, declared in 007 (US2)
- `base64` — 1 file, declared in 007 (US2)
- `observer` — via `factory_bot 4.11.1`, **this feature**

All 97 load errors in the trial traced to that single missing declaration.

### On the "no implementation details" criterion

Applied with the same judgment as spec 007. A runtime upgrade cannot avoid naming the
runtime, but the line held is: **what must be true** (dependency declared, suite passes,
schema untouched, container builds) versus **how to achieve it** (no commands, no file
edits, no prescribed tooling). Even the target patch release is deliberately left to
planning rather than fixed here — the trial used 3.4.9 because it was available locally,
which is not a reason to inherit it as the decision.

### Deliberately deferred to planning

- The specific 3.4 patch release (confirm the newest stable at execution time).
- The mechanism for constraining dependency resolution — the spec requires the constraint
  (FR-007), not a particular command.
- Whether the container base image tag for the chosen patch exists and provides the
  expected toolchain.
- Whether to upgrade `factory_bot` (US3) or carry the `observer` declaration.

### Known verification gap carried over from spec 007

Staging and production boot could not be verified locally, because those configurations
resolve a database host unreachable from the development workstation. That limitation is
unchanged here and applies equally to this feature — FR-014 requires the container build
to succeed, but a full staging boot still needs a host with database access.

### Risk assessment

**Lower than spec 007.** No framework behaviour changes, no API surface changes, no
schema interaction, and the one required change is a single line already proven sufficient.
The main residual risks are environmental rather than logical: native compilation inside
the build container (verified locally but not in the image), and unrelated dependency
drift during lockfile recalculation — the same trap that spec 007 hit and avoided.
