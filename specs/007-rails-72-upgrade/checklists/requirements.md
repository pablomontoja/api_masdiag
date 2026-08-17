# Specification Quality Checklist: Rails 7.2 Upgrade

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

### Revision 4 — clarification session 2026-08-17 (3 questions)

Three ambiguities resolved and integrated into the spec. All were decision points that would have changed implementation or test design, not stylistic gaps.

**Q1 — kit-assignment job timing → adopt post-commit behaviour.** Reading `AssignKitTestsJob` during clarification changed the character of this item. It is not an internal job: it POSTs the kit barcode to an **external partner API** (Lalen/FFTB, institution 83) and retries 10 times with backoff. Under current pre-commit timing, a rolled-back transaction leaves the partner repeatedly told about an assignment never persisted, with no compensating action available. The item was therefore reframed from "decide a timing preference" into **User Story 3: correct partner notification so it cannot precede a committed write** — a defect fix that the upgrade happens to surface, rather than upgrade-compatibility work. FR-013/FR-014 now mandate the behaviour instead of merely requiring a recorded decision, and FR-016 requires an explicit rollback test.

**Q2 — namespace verification gap → smoke-check `regspec`, exclude `patient_portal`.** Coverage is uneven: `patient_portal` and `regspec` had zero request specs, making the all-namespaces equivalence criterion unverifiable for both. The user's split is well-founded and the routes confirm it — `regspec` has seven **write** endpoints persisting to shared LabSample tables on behalf of a consuming app, while `patient_portal` is two read-only index endpoints, currently unused and pending reimplementation. SC-008 now scopes to eight namespaces with the exclusion stated rather than silent; SC-009 requires `regspec` to move from zero to non-zero coverage.

**Q3 — where non-suite behaviour is verified → locally, against a real worker; no staging deploy.** This tightens rather than relaxes the requirement: with no deployment soak, the commit and rollback paths of the partner notification will not be observed incidentally, so FR-033 and SC-016 now require both be exercised deliberately against a running worker. The test environment's in-memory adapter cannot demonstrate the timing change that Q1 approved.

Renumbering after integration: FR-001–FR-034, SC-001–SC-018, five user stories — all verified sequential with no duplicates.

### Revision 3 — Ruby 3.4 evaluated, deferred; latent defect pulled forward

The user asked whether Ruby 3.4 could be raised at the same time, and for other recommendations. Ruby 3.4 was evaluated against this codebase and, by explicit user decision, **excluded from feature 007** — Ruby stays at 3.3.7, with 3.4 to follow as a separate feature after 7.2 is stable.

The evaluation was not wasted: it surfaced a **latent defect that exists today**, independent of either upgrade.

**Finding — undeclared standard library dependencies.** Verified on Ruby 3.4.9, where the interpreter itself warns: *"csv is not part of the default gems starting from Ruby 3.4.0. Install csv from RubyGems."*

- `csv` — required by 6 files (5 recurring mailers + `cera_statistic_creator.rb`), absent from the `Gemfile`.
- `base64` — required by `scanned_docs/ocr_client.rb`, absent from the `Gemfile`, present in the lockfile only transitively.

This became **User Story 2 at P1**, sharing top priority with the assessment. Rationale: it is the only item in the spec that fixes an existing defect rather than enabling an upgrade, it ships today independently of everything else, and the failure mode is silent — these are scheduled report paths, so breakage presents as a report not arriving rather than as an error.

**Second accepted recommendation — three Ruby version pins.** `.ruby-version`, `Gemfile`, and `Dockerfile` (`ARG RUBY_VERSION=3.3.7`) each declare the runtime independently. Captured as FR-011 and SC-004: the invariant must be verified and preserved even though this feature does not change the version.

**Recommendations offered and declined by the user** (recorded so they are not silently lost):

- *Set up CI before upgrading.* No CI exists; all verification is local and single-machine. Already noted as an out-of-scope follow-up in these notes.
- *Explicit API-compatibility contract for ecosystem consumers.* Other apps run Ruby 2.7–3.2, several EOL, and depend on this API. Response-shape equivalence is already covered by FR-015/SC-008; the stronger consumer-contract framing was not added.

Renumbering: five user stories (P1, P1, P2, P3, P4), FR-001–FR-033, SC-001–SC-016, all verified sequential with no duplicates.

### Revision 2 — refined with the 12-item breaking-change guide

The spec was updated after a structured FastRuby.io/OmbuLabs breaking-change guide was supplied. Rather than restating the guide, each of its 12 items was **scanned against this codebase** and the results recorded as a Breaking-Change Audit table in the spec's Context section.

Audit outcome — 6 absent, 2 already compliant, 2 low-risk cleanup, 1 confirmed behavioural hit, 1 low-risk-recheck:

| Verdict | Items |
|---------|-------|
| No occurrences | #3 params comparison, #5 secrets, #6 `check_pending!`, #9 `query_constraints`, #10 mailer `args:`, #12 `alias_attribute` |
| Already compliant | #2 `show_exceptions` (already `:rescuable`), #8 `fixture_path` (commented out; factories only) |
| Cleanup needed | #4 connection access (3 sites, none in request paths), #7 `serialize` (1 positional-coder site) |
| **Confirmed behavioural hit** | **#1 transaction-aware enqueuing — `app/controllers/fv1/kit_controller.rb:45`** |
| Low risk, re-check | #11 queue adapter `at:` support (built-in `:test` adapter) |

The single confirmed hit drove a structural change: transaction-aware enqueuing was promoted to its own user story at **P2**, ahead of the version bump. The reasoning is that the affected call site can be made correct under *both* old and new semantics while still on 7.1, which de-risks the bump and makes that work independently valuable even if the upgrade is deferred.

Four other files containing both a transaction and a job enqueue were checked and cleared — in each, the enqueue sits after the transaction closes. That negative result is recorded because it is the expensive part to re-derive later.

### On the guide's prescriptive content

The supplied guide contains fix-level detail (exact config values, command sequences, dual-boot Gemfile structure). That material was deliberately **not** copied into the spec — it is planning and implementation content. What the spec takes from the guide is *which behaviours change and where this codebase is exposed*; the how belongs to `/speckit-plan`.

One point where the spec deliberately diverges from a literal reading of the guide: the guide presents `enqueue_after_transaction_commit = :never` as a straightforward option. The spec permits it but requires written justification and the narrowest workable scope, because a global opt-out also silently applies to call sites added in future that would benefit from the safer default.

### On the "no implementation details" criterion

This checklist item is applied with judgment rather than literally. The feature *is* a framework upgrade, so version numbers, dependency names, and configuration concepts are the subject matter, not leaked implementation detail — a spec that avoided naming Rails 7.2 would be unusable. The line held instead is:

- **In**: *what* must be true (a dependency verdict exists, the suite passes, schema is untouched, behaviour is equivalent).
- **Out**: *how* to achieve it — no specific commands, no mandated tooling, no prescribed file edits, no step ordering beyond the independently-verifiable-slices constraint.

Dual-boot tooling is explicitly named as optional in Assumptions for exactly this reason: the spec requires independent verifiability and revertibility, and leaves the mechanism to `/speckit-plan`.

### On measured versus assumed facts

The Context section records values verified against the working tree on 2026-08-17 (Rails 7.1.6, Ruby 3.3.7, `load_defaults 7.1`, 737 passing examples in ~36s, no CI present, `alias_attribute` absent, two legacy-syntax enums, one composite-PK model, the `lockbox` compatibility pin, one git-sourced gem). These are observations, not estimates. Planning should re-verify the baseline before relying on it, since the working tree may have moved.

### Deliberately deferred to planning

- Concrete tooling choice for dependency compatibility assessment.
- Whether to dual-boot or upgrade in place.
- Whether a newer 7.1 patch release than 7.1.6 exists at execution time.
- The specific enumeration of 7.2 framework defaults — these change between patch releases and belong in a plan checked against live sources.
- **The actual timing decision for the affected kit-assignment job.** The spec requires the decision be made and recorded; it does not pre-make it, because the right answer depends on what the Lalen partner integration requires when the surrounding transaction rolls back — a domain question, not a framework one. This is the most likely subject for `/speckit-clarify`.
- Whether the two remaining legacy hash-syntax enum declarations are touched — only if 7.2 requires it.

### Audit freshness caveat

The Breaking-Change Audit is a snapshot taken 2026-08-17 against branch `main`. FR-007 requires re-verification at execution time rather than trusting the table. Line numbers in particular drift. The audit exists to size the work and prevent surprises, not to substitute for checking.

### Noted follow-up, out of scope

No CI is configured for this repository. That does not block the upgrade, and adding CI is out of scope here, but it means all verification is local and single-machine. Worth raising separately.
