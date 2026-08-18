# Feature Specification: Rails 7.2 → 8.0 Upgrade

**Feature Branch**: `009-rails-80-upgrade`

**Created**: 2026-08-18

**Status**: Draft

**Input**: User description: "zajmij się teraz zaplanowaniem upgrade z wersji 7.2 do 8.0; ten upgrade może być trudny w przypadku pełnoprawnej aplikacji RoR, ale tu mamy aplikację w trybie API" — accompanied by a twelve-part breaking-change guide drawn from the official Rails 8.0 Release Notes, the Upgrading guide, FastRuby.io and piechowski.io.

## Context

`api_masdiag` is the central API of the Masdiag laboratory ecosystem. Nine sibling applications read and write the shared LabSample database, and several of them — plus two external partners (Lalen/FFTB and Cerascreen) — depend on this API's responses staying byte-identical. The application currently runs Rails 7.2.3 on Ruby 3.4.10, the state left by specs 007 and 008.

This upgrade differs from those two in one decisive way: **it is blocked before it can begin.** Two dependencies declare upper bounds that exclude Rails 8, and one of them has no compatible release in existence. Nothing else can be attempted until both are resolved.

The request's own recommended sequence — "Ruby 3.2+ first, then latest 7.2.x, then Rails 8.0" — is already satisfied. Ruby is at 3.4.10 (spec 008) and Rails at 7.2.3, the current 7.2 patch line. What remains is the framework bump itself.

The upgrade also benefits from the application's shape. It is `config.api_only = true`, so the guide's Action View items (`form_with model: nil`, void-tag content) describe code that does not exist here. A scan confirmed this: zero `form_with` call sites. Likewise, the enum migration the guide calls "the most common problem in practice" was already completed — all thirteen `enum` declarations across eight models use the Rails 7-style positional syntax.

**Verified-clean surfaces** (scanned before writing this spec, so the plan does not budget work that is already done):

| Guide item | Finding |
|---|---|
| Old keyword `enum` syntax | 0 occurrences; all 13 enums already positional |
| `ConnectionPool#connection` | 0 in application code — the four `.connection` hits are Faraday HTTP clients |
| Removed `config.*` flags (7 named in the guide) | 0 occurrences |
| `ActiveSupport::ProxyObject`, `attr_internal_naming_format` | 0 occurrences |
| `Rails::ConsoleMethods`, `rails/console/*` | 0 occurrences |
| `bin/rake stats` | 0 occurrences |
| Action View items (`form_with`, void tags) | Not applicable — API-only |
| Routes with multiple `path:` values | 0 occurrences |
| `Benchmark.ms` | 0 occurrences |
| Active Storage Azure backend | Commented-out example only; MinIO/S3 in use |

What is left is genuinely narrow, which is why this spec spends its weight on the two blockers and on the small number of behavioural changes that a scan cannot rule out.

## Clarifications

### Session 2026-08-18

- Q: Which exit resolves the unmaintained annotation gem (`annotate 3.2.0`, final release, caps Active Record below 8.0)? → A: Replace it with the maintained `annotaterb` fork, preserving the schema-annotation workflow.
- Q: Does this upgrade end with the Rails 8.0 framework defaults active, or stop at the framework bump? → A: Adopt the 8.0 defaults within this upgrade, as a separate verified step after the bump — mirroring spec 007.
- Q: What evidence establishes the byte-identical contract claim across the 11 namespaces? → A: The existing test suite — the same specs passing with unchanged assertions — plus a written per-namespace report. No separate response-fixture capture.
- Q: Is the background-job admin dashboard verified after the upgrade, given it is the app's only asset-serving surface? → A: Yes — it must load and render, verified explicitly as an acceptance criterion.
- Q: Which Rails 8.0 patch does the upgrade target? → A: The latest 8.0.x available at implementation time, pinned exactly and recorded — mirroring spec 008's choice of 3.4.10 over the trial's 3.4.9.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Unblock the dependency graph (Priority: P1)

Two gems currently make `bundle update rails` impossible. Before any framework work, both must be resolved and the resolution proven, with the rest of the lockfile held still.

`rails-i18n 7.0.10` declares `railties (>= 6.0.0, < 8)`. It is a runtime dependency — the application ships Polish and English locales and sets `config.i18n.available_locales = [:pl, :en]`. A compatible 8.0 line exists, so this is a version bump.

`annotate 3.2.0` declares `activerecord (>= 3.2, < 8.0)`. **3.2.0 is the final release of that gem** — no version permits Rails 8, and none will. It is development/test-only, and the decision recorded above is to replace it with the maintained `annotaterb` fork, which continues the same schema-annotation workflow under active maintenance. This is a swap rather than a version bump: the replacement carries its own configuration format, so the existing annotation settings must be carried across and the regenerated output compared against what the old gem produced.

**Why this priority**: Nothing else in the upgrade can start. `bundle update rails` fails at resolution while either bound stands, so every later story depends on this one completing.

**Independent Test**: Dependency resolution against Rails 8.0 succeeds and reports no conflicts, while every gem outside the agreed set stays at its current version. This is testable — and valuable — without changing a line of application code.

**Acceptance Scenarios**:

1. **Given** the current dependency set, **When** resolution is attempted against Rails 8.0, **Then** it fails naming `rails-i18n` and `annotate` — confirming the blockers are real and completely enumerated, not assumed.
2. **Given** the locale gem raised to its Rails 8-compatible line, **When** the application starts and Polish and English locale files are consulted, **Then** every translation key resolves exactly as before, and no message silently falls back to its key.
3. **Given** the annotation gem replaced by its maintained fork, **When** resolution is re-attempted, **Then** it succeeds, and **When** annotations are regenerated, **Then** model files still carry schema annotations and the regenerated blocks are semantically equivalent to the previous ones.
4. **Given** a successful resolution, **When** the dependency lockfile is compared against its previous state, **Then** only the framework gems, the two blockers, and dependencies the framework itself forces have moved. Any unrelated gem movement stops the step.

---

### User Story 2 — Preserve every published API contract (Priority: P1)

Eleven namespaces serve distinct consumers: internal sibling applications, two external partners, and the patient portal. Every response body, status code and error shape must survive the framework change unchanged.

**Why this priority**: This is what the upgrade is measured by. A framework bump that alters a response is a production incident at a diagnostic laboratory, and partner integrations cannot be corrected on our side alone.

**Independent Test**: Run each namespace's request specs before and after the framework change; equivalence holds when the same specs pass with unchanged assertions.

**Acceptance Scenarios**:

1. **Given** an authenticated request to any in-scope namespace, **When** its request specs are run before and after the upgrade, **Then** they pass in both cases with assertions that were not modified in between.
2. **Given** a request that fails validation, **When** issued after the upgrade, **Then** the error shape and status code match the pre-upgrade behaviour exactly — including which field names appear and how they are spelled.
3. **Given** a request with malformed or missing parameters, **When** issued after the upgrade, **Then** rejection happens for the same reason, with the same status code, as before.
4. **Given** authentication with valid and with invalid credentials, **When** issued after the upgrade, **Then** both outcomes match the pre-upgrade behaviour, and no endpoint becomes reachable that was previously refused.

---

### User Story 3 — Keep partner-facing side effects correct (Priority: P1)

Spec 007 fixed a defect where an external partner was notified of a kit assignment that a later rollback discarded. That fix and the framework guarantee behind it must both survive.

Rails 8.0 deprecates the global `enqueue_after_transaction_commit` setting — the framework-level half of the protection adopted in spec 007. The application does not set it explicitly; it inherits the value from `config.load_defaults`. When the default changes, the inherited value may change with it, silently.

**Why this priority**: The failure is irreversible and invisible. A partner told about an assignment that did not commit cannot be untold, and nothing in the response signals that it happened. Spec 007 established that the code-level fix and the framework-level guarantee are two independent layers; this upgrade must not quietly remove one and leave the impression that both are still standing.

**Independent Test**: Run the kit-assignment flow twice — once committing, once forcing a rollback — and count the partner notifications each produced.

**Acceptance Scenarios**:

1. **Given** a kit assignment that commits successfully, **When** the flow completes, **Then** the partner is notified exactly once.
2. **Given** a kit assignment whose transaction is rolled back, **When** the flow completes, **Then** the partner is not notified at all.
3. **Given** the framework's new defaults are adopted, **When** the effective transaction-commit enqueue behaviour is inspected, **Then** its value is recorded explicitly rather than inherited, so a future defaults change cannot alter it unobserved.
4. **Given** background job processing under a real worker, **When** jobs are enqueued and executed, **Then** they are picked up and completed as before, with retry behaviour unchanged.
5. **Given** the job admin dashboard, **When** it is opened after the upgrade, **Then** it renders fully — styling and scripts loading correctly, not merely returning a success status — and still refuses access without valid credentials.

---

### User Story 4 — Adopt the new framework defaults deliberately (Priority: P2)

Rails 8.0 ships behavioural changes that activate only when the new defaults are adopted. Each must be evaluated against this application rather than accepted wholesale.

The one with real teeth here is the new regular-expression timeout. It is a security improvement — it caps how long a pattern may run, protecting against maliciously crafted input — but it converts a slow match into a raised error. The application has six regular-expression sites; one is an email-format validator applied to partner-supplied input, which is exactly the shape of pattern that timeouts are designed to interrupt.

The framework also changes how database schema files are written, reordering columns alphabetically. This produces a large but purely cosmetic difference on the first regeneration. Spec 007 learned this the hard way in a related area: a partial schema regeneration silently dropped two tables and reverted the recorded version. That incident is why schema handling is called out here rather than left implicit.

**Why this priority**: P2 reflects sequencing, not optionality — the upgrade is not finished until the 8.0 defaults are active. It sits after the P1 stories because the bump can be *verified* without them, which is exactly what makes staged adoption worthwhile: a failure that appears only once defaults are switched on is attributable to the defaults rather than to the framework bump.

**Independent Test**: Adopt the new defaults, then confirm the full test suite and every namespace still behave identically. Each default that changes behaviour is recorded with the decision made about it.

**Acceptance Scenarios**:

1. **Given** the new defaults adopted, **When** the full test suite runs, **Then** it produces the same results as before adoption.
2. **Given** email addresses supplied through the partner registration path — valid, invalid, and unusually long — **When** each is validated under the new regular-expression timeout, **Then** validation reaches the same verdict as before and no input causes a timeout error.
3. **Given** each new default that changes behaviour, **When** the upgrade record is read, **Then** it names the default, the decision taken, and the reason.
4. **Given** the schema file is regenerated, **When** the result is compared against the previous version, **Then** every table and column present before is still present, the recorded schema version has not gone backwards, and any difference is confined to column ordering.

---

### User Story 5 — Leave a record the next upgrade can use (Priority: P3)

Record what changed, what was verified, what was deferred, and how to revert.

**Why this priority**: Valuable but not blocking. It matters most for the annotation-gem decision, which a future developer will otherwise rediscover as an unexplained absence, and for the partner-notification layering, which is non-obvious from the code alone.

**Independent Test**: A developer who did not perform the upgrade can read the record and act on it — reverting, or continuing to a later version — without reading the diff.

**Acceptance Scenarios**:

1. **Given** the upgrade is complete, **When** the record is read, **Then** it states the framework version before and after, every dependency that moved and why, and every deferred item with its reason.
2. **Given** a need to revert, **When** the documented procedure is followed, **Then** the application returns to its pre-upgrade state and the test suite reproduces the recorded baseline exactly.

---

### Edge Cases

- **The replacement annotation gem produces different output from the one it replaces.** Its configuration format differs, so a regeneration could reformat every model file at once, burying the upgrade's real diff in noise. Annotation output is compared before accepting the swap, and a wholesale rewrite is treated as a finding rather than an outcome.
- **The replacement annotation gem turns out not to work for this codebase.** The fallback is removing annotations entirely — the capability is development tooling, not runtime behaviour, so losing it must never block the upgrade. If that happens the record must state what was lost.
- **A newer 8.0 patch ships between planning and implementation.** The target is defined as "latest at implementation time", so this is expected rather than exceptional — the plan's assumed version is a placeholder, and the implementation record states which patch was actually installed. Spec 008 hit precisely this and moved from 3.4.9 to 3.4.10.
- **A third blocker emerges only during resolution.** Scanning declared bounds finds gems that *say* they are incompatible; it cannot find gems that merely *are*. Resolution is the authority, and a newly surfaced conflict is treated as a P1 blocker like the first two.
- **A gem resolves against Rails 8 but misbehaves at runtime.** Version bounds are claims, not proof. The test suite and namespace comparison are what actually confirm compatibility.
- **The framework bump requires a dependency the team would rather not move.** The upgrade proceeds under an explicitly recorded exception rather than silently widening scope.
- **Locale files change between the two locale-gem versions.** A translation could resolve differently, or fall back to its key, without any error being raised. Both locales need checking, not just the default.
- **A regular expression that never timed out under load begins timing out under production traffic.** The test suite exercises typical input; a production-scale pattern may behave differently. Any timeout observed in staging is treated as a blocking finding.
- **The job dashboard returns a success status but renders as an unstyled or non-functional page.** Its assets are served by machinery this upgrade changes, and a broken stylesheet does not produce an error status. Checking reachability alone would pass while the dashboard is effectively unusable, so verification means opening it and confirming it renders.
- **The database schema file is regenerated from a database that is behind the repository.** Spec 007 hit exactly this and lost two table definitions. Schema regeneration is only valid from a database at the repository's migration version.
- **A namespace has thin test coverage, so "the suite passes" understates the risk.** Since the suite *is* the equivalence evidence, this is the chosen approach's main limitation rather than a side note: a namespace with few specs yields a correspondingly weak claim. Coverage is not uniform across the eleven namespaces. The gaps are named in the equivalence report rather than papered over, so the residual risk is visible at deployment time instead of being discovered by a partner.
- **A spec fails after the upgrade and the quickest fix is to adjust its expectation.** That converts a detected contract change into a silent one. Any assertion that needs modification to pass is escalated as a finding, and the underlying behavioural difference is explained before the spec is touched.

## Requirements *(mandatory)*

### Functional Requirements

**Blocker resolution**

- **FR-001**: The upgrade MUST begin by proving, through actual dependency resolution rather than inspection, that the set of gems blocking Rails 8.0 is exactly `rails-i18n` and `annotate`, and MUST treat any additional conflict surfaced there as a blocker of equal priority.
- **FR-002**: The localisation gem MUST be raised to a release that permits Rails 8.0, and both configured locales MUST be verified to resolve their translations unchanged afterwards.
- **FR-003**: The unmaintained annotation gem MUST be replaced by the maintained `annotaterb` fork before the framework bump proceeds. The replacement MUST preserve the schema-annotation workflow: annotations MUST still be generated into model files, and regenerating them MUST leave the existing annotation blocks semantically equivalent rather than rewriting every model file wholesale.
- **FR-004**: Dependency resolution MUST be constrained so that only the framework, the two blockers, and gems the framework itself forces are permitted to move. Any other gem movement MUST stop the step for investigation.

**Framework bump**

- **FR-005**: The framework MUST be raised from 7.2.3 to the **latest 8.0.x patch available at implementation time**, pinned to that exact patch rather than left to float across the 8.0 line. The chosen version MUST be recorded, and if it differs from the version assumed during planning, the reason MUST be recorded with it.
- **FR-006**: Configuration changes the framework's own upgrade tooling proposes MUST be reviewed individually and either applied with a reason or rejected with a reason. Bulk acceptance is not permitted.
- **FR-007**: The application MUST start successfully in the development, test and staging configurations after the bump.
- **FR-008**: The container image MUST build and the application MUST start inside it, since the container toolchain differs from the workstation's and is what production actually runs.
- **FR-008a**: The background-job admin dashboard MUST load and render after the upgrade, with its styling and scripts served correctly — not merely be reachable or return a non-error status. It is the application's only asset-serving surface, and it configures no asset settings of its own, so it depends entirely on framework defaults that this upgrade changes.
- **FR-008b**: The dashboard MUST remain protected by its existing authentication after the upgrade: valid credentials admitted, invalid credentials refused, and the dashboard MUST NOT become reachable without credentials.

**Contract preservation**

- **FR-009**: Every one of the eleven namespaces MUST return byte-identical responses — body, status code and headers — for equivalent requests before and after the upgrade. Equivalence MUST be established by the existing test suite: the same request specs passing with **unchanged assertions**. Weakening, relaxing or deleting an assertion to make a spec pass after the upgrade MUST be treated as a contract change, not a test fix.
- **FR-009a**: A per-namespace equivalence report MUST record, for each of the eleven namespaces, which specs were exercised and what coverage they represent — explicitly naming any namespace whose coverage is too thin for the suite alone to substantiate the equivalence claim.
- **FR-010**: Authentication MUST continue to accept valid credentials and refuse invalid ones identically across every namespace, and no endpoint MUST become reachable that was previously refused.
- **FR-011**: Validation failures MUST produce identical error shapes and status codes, including field naming.
- **FR-012**: Parameter handling MUST reject the same malformed and missing-parameter requests, for the same reasons, with the same status codes. The framework's newer parameter-handling style MUST NOT be adopted as part of this upgrade.

**Behavioural safety**

- **FR-013**: Partner notification MUST fire exactly once when a kit assignment commits and not at all when it rolls back, verified against a real background worker rather than an inline test adapter.
- **FR-014**: The transaction-commit enqueue behaviour MUST be set explicitly rather than inherited from framework defaults, so that a future defaults change cannot alter it silently.
- **FR-015**: Field-level encrypted values written before the upgrade MUST decrypt correctly after it, verified against data persisted prior to the change rather than data created afterwards.
- **FR-016**: Background jobs MUST continue to be enqueued, picked up and retried as before.
- **FR-017**: Every regular expression applied to externally supplied input MUST be verified to reach the same verdict under the new timeout behaviour, using valid, invalid and unusually long inputs.

**Defaults adoption**

- **FR-018**: The upgrade MUST end with the Rails 8.0 framework defaults active. They MUST be adopted as a distinct, separately verifiable step after the framework bump is verified, so that a failure can be attributed to one or the other. The upgrade is not complete while defaults remain at 7.2.
- **FR-019**: Each new default that changes behaviour MUST be recorded with the decision taken and the reason.
- **FR-020**: Regenerating the database schema file MUST NOT remove any table or column, and MUST NOT move the recorded schema version backwards. It MUST only be done from a database at the repository's current migration version.

**Verification and record**

- **FR-021**: A test baseline MUST be recorded before any change and MUST be reproducible on demand.
- **FR-022**: The test suite MUST show no reduction in example count and no failures after the upgrade.
- **FR-023**: Warnings and deprecation messages emitted after the upgrade MUST each be resolved or recorded with a rationale.
- **FR-024**: A written record MUST be produced covering what changed, what was verified, what was deferred and how to revert.
- **FR-025**: A revert procedure MUST be documented and MUST restore the recorded baseline exactly. It MUST revert the framework version and the dependent code together, since reverting one without the other is known from spec 007 to produce failures that mask the real state.

### Key Entities

- **Namespace**: A versioned group of endpoints serving one consumer type — eleven in total (`v1`, `fv1`, `nume`, `lalen`, `toxo`, `masdiag`, `masdiag_mailer`, `patient_portal`, `regspec`, `webhook`, `diagnostyka_precyzyjna`). The unit at which contract equivalence is verified.
- **Blocking dependency**: A gem whose declared version bounds exclude Rails 8.0. Two are known: one with a compatible newer release, one with none.
- **Framework default**: A behaviour that activates only when the new defaults version is adopted. Each is a separate decision with its own recorded rationale.
- **Baseline**: The recorded pre-upgrade state — test example count, failure count, framework version, dependency lockfile, commit reference. Every "unchanged" claim is measured against it.
- **Upgrade record**: The written account of what changed, what was verified, what was deferred, and how to revert.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Dependency resolution against the target Rails 8.0 patch succeeds with zero conflicts, and the resolved framework version matches the latest 8.0.x published at implementation time. *(FR-001, FR-002, FR-003, FR-004, FR-005)*
- **SC-002**: Exactly two blocking dependencies are resolved — the locale gem by version bump, the annotation gem by replacement — and after the swap every model file that carried a schema annotation still carries one. *(FR-002, FR-003)*
- **SC-003**: The dependency lockfile shows movement only in the framework gems, the two blockers, and gems the framework forces — zero unrelated gem movements. *(FR-004)*
- **SC-004**: All 98 test files execute with zero failures and no reduction in example count against the recorded baseline. *(FR-021, FR-022)*
- **SC-005**: All 11 namespaces pass their request specs after the upgrade with zero assertions modified, and the per-namespace report names every namespace whose coverage is too thin to substantiate the claim on the suite alone. *(FR-009, FR-009a)*
- **SC-006**: Authentication produces identical accept/refuse outcomes across all 11 namespaces, with zero endpoints becoming newly reachable. *(FR-010)*
- **SC-007**: Validation failures and malformed-parameter rejections produce identical error shapes and status codes. *(FR-011, FR-012)*
- **SC-008**: A committed kit assignment produces exactly 1 partner notification; a rolled-back one produces 0 — observed against a real worker. *(FR-013)*
- **SC-009**: The transaction-commit enqueue behaviour is set explicitly, verifiable without reference to framework defaults. *(FR-014)*
- **SC-010**: Encrypted values written before the upgrade decrypt correctly after it, at a 100% success rate. *(FR-015)*
- **SC-011**: All 6 regular-expression sites reach identical verdicts under the new timeout behaviour, with zero timeout errors across valid, invalid and long inputs. *(FR-017)*
- **SC-012**: Both configured locales resolve every translation key unchanged, with zero keys falling back to their own name. *(FR-002)*
- **SC-013**: The application starts successfully in all 3 non-production configurations and inside the container image. *(FR-007, FR-008)*
- **SC-013a**: The upgrade concludes with the 8.0 framework defaults active, and the full suite and all 11 namespaces are verified twice — once after the bump with defaults still at 7.2, and once after adoption. *(FR-018)*
- **SC-013b**: The job admin dashboard renders fully after the upgrade with zero failed asset requests, and refuses access without valid credentials. *(FR-008a, FR-008b)*
- **SC-014**: Schema regeneration removes zero tables and zero columns, and the recorded schema version does not decrease. *(FR-020)*
- **SC-015**: Every warning and deprecation message emitted after the upgrade is resolved or recorded — zero unaddressed. *(FR-023)*
- **SC-016**: The revert procedure restores the baseline exactly, reproducing the recorded example and failure counts. *(FR-025)*
- **SC-017**: A developer who did not perform the upgrade can revert it, or continue to a later version, using the record alone. *(FR-024)*

## Assumptions

- **Prerequisites are already met.** The request's recommended sequence puts Ruby 3.2+ and the latest 7.2.x patch before the framework bump. Both hold: Ruby 3.4.10 (spec 008) and Rails 7.2.3.
- **The application stays API-only.** `config.api_only = true`, so the guide's Action View items describe code that does not exist here. Confirmed: zero `form_with` sites.
- **Enum migration is already complete.** All 13 enum declarations use positional syntax. The guide's "most common problem" does not apply.
- **Eleven namespaces are in scope**, taken from the route definitions rather than from the project's summary table, which lists nine and omits `toxo` and `diagnostyka_precyzyjna`. `patient_portal` is included in structural verification but excluded from behavioural comparison, per the clarification recorded in spec 007 — it is currently unused and its implementation may change.
- **New optional framework subsystems are out of scope.** The deployment tooling and the authentication generator are opt-in and unrelated to this upgrade's purpose. The application already uses the database-backed queue. The asset pipeline is a partial exception: the application does not adopt it, but the job admin dashboard already depends on it through its own gem, so the upgrade must not break that dashboard.
- **The job admin dashboard is the only asset-serving surface.** It sets no asset configuration of its own, so it inherits framework defaults entirely — which is precisely why this upgrade can break it without touching any application code.
- **The newer parameter-handling style is out of scope.** The existing style continues to work; adopting the alternative across 25 call sites is a refactor with its own risk, not part of a framework bump.
- **The database schema does not change.** This is a framework upgrade. Any schema difference is a defect in the upgrade, not an outcome of it — and the shared LabSample database makes unreviewed schema change a cross-application hazard.
- **Verification is local plus staging.** Consistent with specs 007 and 008; production verification is deferred to deployment.
- **The annotation gem is development-tooling only.** Replacing it cannot affect runtime behaviour. This is what makes the chosen replacement low-risk, and what keeps outright removal available as a fallback if the fork does not work out.
- **Continuous integration does not exist.** Verification is manual and local, as in specs 007 and 008. The constitution was amended in spec 007 precisely because it described a CI gate that is not in place.

## Out of Scope

- Migrating the application to the new asset pipeline as a deliberate architectural change. The application is API-only and serves assets from exactly one place — the job admin dashboard, which already depends on the newer pipeline through its own gem. Keeping that dashboard rendering (FR-008a) is in scope; adopting the pipeline anywhere else is not.
- Adopting the new deployment tooling or proxy.
- Adopting the authentication generator.
- Converting parameter handling to the newer style.
- Upgrading the test-factory library — deferred from spec 008, still deferred, and still the thing that would retire the `observer` declaration.
- Any schema or data migration.
- Production deployment and verification.
- Upgrading gems unrelated to the framework bump.
