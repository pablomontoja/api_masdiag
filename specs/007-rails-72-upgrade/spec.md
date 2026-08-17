# Feature Specification: Rails 7.2 Upgrade

**Feature Branch**: `007-rails-72-upgrade`

**Created**: 2026-08-17

**Status**: Draft

**Input**: User description: "przygotuj się do aktualizacji Ruby on Rails" — upgrade api_masdiag from Rails 7.1 to Rails 7.2, using the official upgrade guide, 7.2 release notes, RailsBump gem-compatibility checks, dual-boot tooling, and community walkthroughs as reference material. Refined with a structured 12-item breaking-change guide (FastRuby.io / OmbuLabs), each item of which has been audited against this codebase — see the Breaking-Change Audit below.

## Context

`api_masdiag` is the central API of the Masdiag ecosystem and the strategic direction is for every other app to talk to it instead of the shared LabSample database directly. That makes this application the highest-consequence upgrade target in the fleet: an outage here degrades many downstream apps at once, and a silent behaviour change can corrupt diagnostic sample data that other apps read.

Verified current state (measured on branch `main`, 2026-08-17):

| Property | Value |
|----------|-------|
| Rails | 7.1.6 (`Gemfile` pin `~> 7.1.5, >= 7.1.5.1`) |
| Ruby | 3.3.7 (already above the 3.1 minimum Rails 7.2 requires) |
| `config.load_defaults` | `7.1` |
| Database | MySQL via `mysql2 ~> 0.5`, shared LabSample schema |
| Background jobs | Solid Queue 1.4.0 |
| Test suite | RSpec, 737 examples, 0 failures, ~36s |
| Environments | development, test, staging, production |
| CI | none — no `.github/workflows`, no `.gitlab-ci.yml` |

### Breaking-Change Audit

Each of the 12 documented 7.1→7.2 breaking changes has been scanned against this codebase. This audit is a **starting hypothesis for planning, not a completed remediation** — findings are recorded so planning can size the work, and each must be re-verified at execution time.

| # | Change | Priority | Finding in this codebase |
|---|--------|----------|--------------------------|
| 1 | Transaction-aware job enqueuing | 🔴 High | **1 confirmed hit — and it is an existing defect.** `app/controllers/fv1/kit_controller.rb:45` calls `assign_tests_in_lalen_api` inside the transaction opened at line 39, which enqueues `LalenApi::AssignKitTestsJob` — an **external partner notification** (Lalen / FFTB, institution 83) carrying the kit barcode, with `retry_on ... attempts: 10`. A rollback therefore leaves the partner repeatedly told about an assignment never persisted locally. **Resolved by clarification: adopt post-commit timing.** Four other files containing both a transaction and an enqueue were checked and are **not** affected — the enqueue sits after the transaction closes. `app/models/sample.rb:112` and `app/models/reserved_sample_code.rb:101` enqueue from public methods, not callbacks. `enqueue_after_transaction_commit` is not configured anywhere. |
| 2 | `show_exceptions` requires symbols | 🔴 High | **Already compliant.** Only `config/environments/test.rb:32` sets it, already to `:rescuable`. No boolean values remain. |
| 3 | `params` no longer compares equal to `Hash` | 🔴 High | **No occurrences** in `app/` or `spec/`. |
| 4 | `ActiveRecord::Base.connection` deprecated | 🔴 High | **3 call sites.** `db/migrate/20260311113835_toxicology_quant_project.rb:229,233` and `spec/services/hl7/measurement_importer_spec.rb:57`. All are outside production request paths (a historical migration and one spec), so this is deprecation-warning cleanup rather than a functional risk. |
| 5 | `Rails.application.secrets` removed | 🔴 High | **No occurrences.** The application already uses Rails credentials throughout. |
| 6 | `Migration.check_pending!` removed | 🔴 High | **No occurrences** in `spec/`, `config/`, or `lib/`. No healthcheck gem invoking it is present. |
| 7 | `serialize` requires `type:`/`coder:` | 🟡 Medium | **1 legacy-syntax site.** `app/models/key_value_db_store.rb:5` passes the coder positionally (`serialize :json, ::ActiveRecord::Coders::JSON`) rather than as a keyword. The three sites in `app/models/shop_order.rb:27-29` already use `type:`. |
| 8 | `fixture_path` → `fixture_paths` | 🟡 Medium | **Not applicable.** The only occurrence (`spec/rails_helper.rb:46`) is commented out; the project uses factories exclusively, no fixtures. |
| 9 | `query_constraints` deprecated | 🟡 Medium | **No occurrences.** |
| 10 | Mailer test `args:` → `params:` | 🟡 Medium | **Not applicable.** No `assert_enqueued_email_with` or `have_enqueued_mail` usages — the suite is RSpec and asserts on mailers differently. |
| 11 | Queue adapter must support `at:` in tests | 🟡 Medium | **Low risk.** `config/environments/test.rb` uses the built-in `:test` adapter, which supports `at:`. Two specs manipulate the adapter directly (`spec/jobs/masdiag_mailer/contractor_results_notifier_job_spec.rb:23`, `spec/services/notifications/sender_spec.rb:10`) and should be re-checked. |
| 12 | `alias_attribute` behaviour change | 🟡 Medium | **No occurrences** in `app/`, `lib/`, or `config/`. |

**Net assessment**: the codebase is in better shape than a typical 7.1 app. Of 12 documented changes, 6 are entirely absent, 2 are already compliant, 2 are low-risk cleanup, and **1 (transaction-aware enqueuing) is a confirmed behavioural hit — now resolved by clarification in favour of adopting the new post-commit timing, which also fixes an existing partner-notification defect**.

Additional risk surfaces outside the 12-item list:

- **Enum syntax**: most models use the keyword form; two legacy hash-form declarations remain (`app/models/test.rb:27`, `app/models/scanned_doc.rb:7`).
- **Composite primary keys**: `app/models/analyte_result.rb`; the `composite_primary_keys` gem is commented out in the `Gemfile`, so this relies on native Rails support.
- **Pinned-for-compatibility gems**: `lockbox ~> 1.2.0` carries an explicit comment that ">= 2.2 refuses to load on Active Record 7.1" — this pin must be re-evaluated against 7.2 rather than carried forward blindly.
- **Git-sourced gem**: `k-php-serialize` from `pablomontoja/php-serialize` — outside RubyGems, so RailsBump cannot assess it and it needs manual verification.
- **Not applicable to an API-only app**: the 7.2 additions of browser-version restrictions (`allow_browser`), PWA scaffolding, and DevContainers target full-stack applications. `api_masdiag` is API-only, so these are out of scope and must not be adopted reflexively from `rails app:update` output.

### Ruby version: 3.4 considered and deliberately deferred

Raising Ruby to 3.4 at the same time as Rails was evaluated and **excluded from this feature's scope** by explicit decision. Ruby stays at **3.3.7** throughout. The reasoning:

- Official upgrade guidance is to change one variable at a time. Moving both means that a failure gives no signal about whether the framework or the language caused it, and a rollback reverts both. For the ecosystem's central API, that trade is not worth one saved test cycle.
- Ruby 3.3 remains supported well beyond this work, so there is no deadline forcing the two together.
- Rails 7.2 officially supports Ruby 3.4, so doing Rails first leaves the Ruby step fully available afterwards — the ordering costs nothing.

A Ruby 3.4 upgrade is expected to follow as **a separate feature**, once 7.2 is stable. One finding from that evaluation is, however, pulled *into* this feature because it is a live latent defect (see below).

### Latent defect found while evaluating Ruby 3.4 — in scope

`csv` and `base64` stopped being Ruby default gems in 3.4. Verified directly on Ruby 3.4.9, where `require "csv"` fails with Ruby's own warning: *"csv is not part of the default gems starting from Ruby 3.4.0. Install csv from RubyGems."*

In this codebase:

- **`csv` is required by 6 files** — `app/mailers/masdiag_recurring/daily_hospital_samples_zipper_mailer.rb`, `monthly_ptc_summary_mailer.rb`, `daily_lalen_incoming_samples_mailer.rb`, `daily_cerascreen_dao_declaration_mailer.rb`, `monthly_hospital_summary_mailer.rb`, and `app/services/masdiag_recurring/cera_statistic_creator.rb` — and appears **nowhere in the `Gemfile`**.
- **`base64` is required by** `app/services/scanned_docs/ocr_client.rb` and is likewise absent from the `Gemfile`, present in the lockfile only as a transitive dependency of other gems.

Both are recurring-job and mailer code paths, so a failure would surface as scheduled reports silently not being produced rather than as an obvious request error. Declaring both explicitly is safe on Ruby 3.3.7 today, is independent of both upgrades, and removes a blocker from the future Ruby work in advance. It is therefore included here.

### Ruby version is pinned in three places

`.ruby-version` (`ruby-3.3.7`), `Gemfile` (`ruby "3.3.7"`), and `Dockerfile` (`ARG RUBY_VERSION=3.3.7`). These must agree; a divergence typically presents as working locally and failing in the deployed image. This spec does not change the Ruby version, but requires the invariant be verified and preserved.

## Clarifications

### Session 2026-08-17

- Q: For the kit-assignment job enqueued inside a transaction, should the new post-commit timing be adopted, or should current timing be preserved? → A: Adopt the new post-commit behaviour — the job runs only after the transaction commits, and does not run at all if it rolls back.

**Why this matters beyond timing**: the affected job notifies an **external partner system** (Lalen, institution 83 / FFTB) about a kit's test assignment, and it retries with backoff on failure. Under the current pre-commit timing, a transaction that rolls back leaves the partner told about an assignment this system never persisted — and the retry policy means it keeps insisting. There is no compensating action to withdraw such a notification. Adopting post-commit timing therefore **corrects an existing data-consistency defect** rather than merely relocating a call, which is why this is treated as a fix and not only as upgrade compatibility work.

- Q: Two namespaces (`patient_portal`, `regspec`) have no request specs, making the all-namespaces equivalence criterion unverifiable for them. How should that gap be closed? → A: Add minimal smoke checks for `regspec` only; exclude `patient_portal` from the requirement.

**Rationale for the asymmetry**: `regspec` exposes seven **write** endpoints (create/update across institutions, contractors, samples, patients) that persist to the shared LabSample database on behalf of a consuming application — precisely where an upgrade regression would cause durable damage, and precisely what a green suite elsewhere would not catch. `patient_portal` is dormant: two read-only index endpoints, not currently in use, with its implementation expected to change. Investing verification effort there would test behaviour that is due to be replaced, so it is explicitly excluded from the equivalence requirement rather than left as an unstated gap.

- Q: Where should behaviour the automated suite cannot reach — real job processing and production-configuration deprecation output — be verified before release? → A: Locally, against a real background-job worker process in the development environment; no staging deployment required.

**Consequence for scope**: verification of job-timing behaviour is a local activity, not a deployment gate. This keeps the upgrade self-contained but means the rollback path for the partner notification must be exercised deliberately and locally — it will not be caught incidentally by a staging soak. The test environment uses an in-memory job adapter while every other environment uses the real background-job backend, so the local run against a real worker is the only place the adopted post-commit timing is actually observed end to end.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Establish a trustworthy upgrade baseline and compatibility verdict (Priority: P1)

Before anything changes, the developer needs an authoritative, written answer to "can this application move to 7.2 at all, and what will it cost?" — a recorded green baseline of the current suite, a per-dependency compatibility verdict for every gem in the lockfile, and a catalogue of every place in this codebase that a documented 7.2 behaviour change actually touches.

**Why this priority**: This is the only story that delivers value even if the upgrade is ultimately deferred. A compatibility report that says "gem X blocks us until it releases version Y" is a complete, useful deliverable on its own, and it prevents the far more expensive failure mode of discovering a hard blocker halfway through a half-migrated codebase. It also produces the baseline that every later story is measured against.

**Independent Test**: Can be fully tested by reading the produced report: every gem in the lockfile appears with a verdict, every documented 7.2 breaking change appears with either an affected-locations list or an explicit "not applicable to this codebase" finding, and the recorded baseline matches a freshly run suite. Delivers value as a go/no-go decision document with no code change whatsoever.

**Acceptance Scenarios**:

1. **Given** the application on Rails 7.1.6, **When** the baseline is captured, **Then** the recorded result states the exact example count, failure count, and runtime of the current suite, and a rerun reproduces the same pass/fail outcome.
2. **Given** the current lockfile, **When** dependency compatibility is assessed, **Then** every gem is classified as compatible / needs-version-bump / unknown-needs-manual-check / blocking, and each non-compatible verdict names the specific constraint and the required action.
3. **Given** the `lockbox ~> 1.2.0` pin justified by an Active Record 7.1 comment, **When** the assessment runs, **Then** the report states explicitly whether that pin can be lifted on 7.2 and what version becomes viable.
4. **Given** the git-sourced `k-php-serialize` gem, **When** automated compatibility checking cannot cover it, **Then** the report flags it as requiring manual verification rather than silently omitting it.
5. **Given** the published list of 7.1→7.2 breaking changes, **When** the codebase is scanned, **Then** each change is recorded either with concrete affected file locations or with an explicit finding that it does not apply.
6. **Given** the Breaking-Change Audit recorded in this spec, **When** each finding is re-verified against the working tree at execution time, **Then** every entry is confirmed still accurate or corrected, so that no remediation is skipped because of a stale finding.

---

### User Story 2 — Declare implicitly-relied-upon standard library dependencies (Priority: P1)

Several recurring-report and document-processing code paths rely on standard library components that are no longer guaranteed to be present in newer language runtimes. The developer declares these as explicit dependencies so the application states what it actually needs, rather than depending on what the runtime happens to bundle.

**Why this priority**: Shares P1 with the assessment because it is the one change here that fixes a latent defect rather than enabling an upgrade, and it can ship today, independently of everything else. The affected paths are scheduled reports and mailers, so the failure mode is silent — reports stop being produced without an obvious error. It is also a strict prerequisite for the future language-runtime upgrade, so doing it now removes a blocker from that work at no cost.

**Independent Test**: Can be fully tested on the current runtime by declaring the dependencies and confirming the suite stays green and the affected report-generation paths still work. Delivers value immediately, with no relation to the framework upgrade.

**Acceptance Scenarios**:

1. **Given** code paths that load standard library components not declared as dependencies, **When** the dependency list is audited, **Then** every such component is identified with the files that require it.
2. **Given** those components are declared explicitly, **When** the application runs on the current runtime, **Then** behaviour is unchanged and the full suite passes.
3. **Given** the affected report-generation and document-processing paths, **When** they are exercised after the change, **Then** they produce the same output as before.
4. **Given** a runtime that no longer bundles these components, **When** the application is loaded against it, **Then** the components resolve from declared dependencies rather than failing at require time.

---

### User Story 3 — Correct partner notification so it cannot precede a committed write (Priority: P2)

The kit-assignment workflow notifies an external partner system about which tests are assigned to a kit. That notification is currently triggered from inside the same database transaction that records the assignment, so a transaction that rolls back leaves the partner holding information this system never persisted — and the notification retries, so it persists in asserting it. The developer makes the notification conditional on the write actually committing.

**Why this priority**: This is a data-consistency defect affecting an external party, not merely upgrade compatibility. It ranks above the version bump because the same framework change that surfaces it also fixes it: adopting post-commit timing is both the upgrade-correct choice and the correct choice on its own merits. It is independently valuable because the call site can be made correct on the current framework version, before anything else moves.

**Independent Test**: Can be fully tested on the current framework version by making the notification fire only after the surrounding write commits, then confirming that a rolled-back assignment produces no partner notification and a successful one still does. Delivers value as a defect fix regardless of whether the upgrade proceeds.

**Acceptance Scenarios**:

1. **Given** an assignment whose surrounding transaction commits successfully, **When** the workflow completes, **Then** the partner is notified exactly once with the assigned tests.
2. **Given** an assignment whose surrounding transaction rolls back, **When** the workflow completes, **Then** the partner is not notified at all, and no retry attempts are made.
3. **Given** the notification is retried after a transient partner-side failure, **When** the retries occur, **Then** they only ever concern an assignment that was actually persisted.
4. **Given** the corrected behaviour, **When** the full suite runs on the current framework version, **Then** it passes with zero failures, demonstrating the fix is safe ahead of the version bump.
5. **Given** the framework version later moves to 7.2, **When** the same workflow runs, **Then** its observable behaviour is unchanged, because the code no longer depends on which enqueuing semantics apply.
6. **Given** other enqueue sites currently outside transactions, **When** the audit is re-verified, **Then** any newly introduced in-transaction enqueue is caught rather than assumed absent.

---

### User Story 4 — Run the application on Rails 7.2 with 7.1 framework defaults (Priority: P3)

The developer moves the framework version to 7.2 while deliberately leaving `config.load_defaults` at `7.1`, so that the version bump and the behavioural defaults change are two separately verifiable steps rather than one entangled one. The application boots, the full suite passes, and every namespace still answers as before.

**Why this priority**: This is the smallest independently deployable slice that actually delivers the upgrade. Separating the version bump from the defaults flip means that if something breaks, the cause is unambiguous. An application running 7.2 on 7.1 defaults is a legitimate, supported, shippable end state — the defaults migration can follow later without blocking the security and maintenance benefits of being on 7.2.

**Independent Test**: Can be fully tested by booting the application on 7.2 and running the complete suite: it must reach the same 737 passing examples with zero failures, and every API namespace must return responses equivalent to the 7.1 baseline. Delivers value as a shippable upgrade even if Story 5 never happens.

**Acceptance Scenarios**:

1. **Given** dependencies resolved for 7.2, **When** the application boots in each of the four environments, **Then** boot succeeds with no errors.
2. **Given** the 7.2 framework with defaults still at 7.1, **When** the full test suite runs, **Then** the pass/fail outcome matches the recorded baseline with zero failures and no reduction in example count.
3. **Given** an authenticated request to each in-scope API namespace (v1, fv1, nume, lalen, masdiag, masdiag_mailer, regspec, webhook — `patient_portal` excluded as dormant), **When** the request is served on 7.2, **Then** the response status and body structure match the 7.1 baseline for the same request.
4. **Given** the `regspec` namespace has no existing request specs, **When** verification is prepared, **Then** a minimal smoke check exists for each of its write endpoints, sufficient to compare status and body shape before and after the upgrade.
5. **Given** the shared LabSample database, **When** the upgraded application reads and writes sample, measurement, and result records, **Then** the stored values are identical to what 7.1 produced, and no database schema change is introduced by the upgrade.
6. **Given** background job processing, **When** jobs are enqueued and executed on 7.2, **Then** they enqueue to the same queues and execute with the same outcomes as on 7.1.
7. **Given** the composite-primary-key model and the field-level encrypted attributes, **When** exercised on 7.2, **Then** records are found, written, and decrypted correctly.
8. **Given** the upgrade is complete, **When** deprecation output from the suite is reviewed, **Then** every warning is either resolved or recorded with a rationale for deferring it.
9. **Given** the legacy-syntax serialization declaration and the deprecated connection-access call sites identified in the audit, **When** the upgrade is complete, **Then** each is either migrated to the supported form or recorded as a deliberate deferral.

---

### User Story 5 — Adopt Rails 7.2 framework defaults deliberately (Priority: P4)

With the application stable on 7.2, the developer reviews each new 7.2 default individually, decides whether to adopt it, and moves `config.load_defaults` to `7.2` — keeping explicit overrides for any default that is not appropriate for this application.

**Why this priority**: This is genuinely optional for the upgrade to be considered done and carries the highest behaviour-change risk per line of configuration. Deferring it does not block being on 7.2, but doing it eventually is what prevents accumulating configuration debt that makes the next upgrade (7.2 → 8.x) harder. Doing it last means each default is evaluated against a known-good 7.2 application rather than against a moving target.

**Independent Test**: Can be fully tested by flipping the defaults and confirming the suite stays green while each new default has a recorded adopt-or-override decision. Delivers value as reduced configuration debt, independently of the earlier stories being revisited.

**Acceptance Scenarios**:

1. **Given** the application stable on 7.2, **When** the new framework defaults are enumerated, **Then** each one has a recorded decision to adopt or to override, with a reason.
2. **Given** the defaults are moved to 7.2, **When** the full suite runs, **Then** it passes with zero failures.
3. **Given** a default judged inappropriate for this application, **When** it is overridden, **Then** the override is explicit and carries a comment explaining why.
4. **Given** the defaults change alters externally visible API behaviour in any namespace, **When** that is detected, **Then** the change is either reverted via override or recorded as an intentional, documented behaviour change.
5. **Given** the configuration-diff review surfaces additions that target full-stack applications rather than API-only ones, **When** those are evaluated, **Then** they are explicitly declined rather than adopted, and the decision is recorded.

---

### Edge Cases

- **A dependency has no 7.2-compatible release.** The upgrade must stop at a recorded blocker rather than proceeding with a forced or vendored resolution. Replacing or forking a gem is a separate decision, not part of this upgrade.
- **The `lockbox` pin cannot be lifted.** Field-level encryption protects patient data; if no version of the encryption library works on 7.2, the upgrade is blocked and must be reported as blocked, never worked around by weakening or bypassing encryption.
- **The suite passes but a downstream app breaks.** Other apps in the ecosystem consume this API; response-shape equivalence must be verified explicitly, because a green suite here does not prove downstream compatibility.
- **A change would alter the shared LabSample schema.** Any such change is out of scope and must be escalated, since other apps read the same tables.
- **A transaction rolls back after a job was enqueued inside it.** Under the adopted post-commit behaviour the job never runs — which for the kit-assignment workflow is the correct outcome, since the partner should not learn of an assignment that was not persisted. Resolved by clarification.
- **A partner notification was already sent under the old timing before this fix ships.** Any assignment notified to the partner but rolled back locally is already inconsistent today. Whether such records exist and need reconciling is a data question outside this upgrade, but it should not be assumed that fixing the code repairs history.
- **An in-transaction enqueue is introduced between the audit and execution.** The audit is a snapshot; the scan must be repeated at execution time rather than trusted as permanently accurate.
- **A job enqueued in a transaction depends on being processed before commit.** If any workflow genuinely requires the old timing, adopting the new default breaks it silently — no exception is raised, the job merely runs later or not at all.
- **`rails app:update` offers full-stack scaffolding.** This is an API-only application; browser-version guards, PWA files, and DevContainer configuration must be declined rather than accepted wholesale from the generated diff.
- **Composite-primary-key finder behaviour shifts.** `analyte_result` relies on native composite key support with the dedicated gem disabled; changes here can silently return wrong rows rather than raising.
- **Deprecation warnings that only appear in production-like configuration.** Test and development report deprecations, but staging and production suppress them, so warnings surfacing only under production settings can go unseen.
- **A behaviour change appears only under real background-job processing.** The test environment uses the in-memory test adapter while every other environment uses Solid Queue, so adapter-specific differences will not surface in the suite. Because verification is local rather than a staging soak, these paths must be exercised on purpose or they will not be exercised at all.
- **Rollback is needed after deployment.** Because no CI exists, the upgrade must be revertible to the exact 7.1.6 dependency set that produced the recorded baseline.
- **An undeclared standard library component fails only on a scheduled run.** The affected paths are recurring mailers and report generators, so a load failure would surface as a report silently not arriving rather than as a failing request — the kind of defect that can go unnoticed for a full reporting cycle.
- **The three Ruby version pins drift apart.** `.ruby-version`, `Gemfile`, and `Dockerfile` each state the runtime version independently; if they diverge, the application can pass every local check and still run on a different runtime once containerised.
- **Declaring a standard library component resolves a different version than the runtime bundled.** Making an implicit dependency explicit can pull a newer release than the one previously in use, so behaviour must be confirmed rather than assumed identical.

## Requirements *(mandatory)*

### Functional Requirements

**Assessment**

- **FR-001**: The upgrade MUST begin by recording a reproducible baseline of the current application's test outcome, and that baseline MUST be the reference for all later verification.
- **FR-002**: Every dependency in the lockfile MUST receive an explicit compatibility verdict against Rails 7.2: compatible, needs-version-bump, unknown-needs-manual-check, or blocking.
- **FR-003**: Dependencies that automated compatibility tooling cannot assess — specifically the git-sourced gem — MUST be flagged for manual verification rather than omitted or assumed compatible.
- **FR-004**: Every dependency pinned specifically for Rails-version compatibility MUST be re-evaluated against 7.2, with a recorded verdict on whether the pin can be lifted.
- **FR-005**: Each documented 7.1→7.2 breaking change MUST be recorded either with the concrete locations it affects in this codebase or with an explicit finding that it does not apply.
- **FR-006**: If any dependency is found to be blocking, the assessment MUST report the upgrade as blocked, naming the dependency and the condition that would unblock it, rather than proceeding.
- **FR-007**: Every finding in the Breaking-Change Audit MUST be re-verified against the working tree at execution time before it is acted on or dismissed, since the audit is a point-in-time snapshot.

**Dependency declaration and runtime version**

- **FR-008**: Every standard library component that application code loads at runtime MUST be declared as an explicit dependency, rather than relied upon as something the language runtime happens to bundle.
- **FR-009**: Declaring these dependencies MUST NOT change behaviour on the current runtime, and MUST be verifiable independently of the framework upgrade.
- **FR-010**: The language runtime version MUST remain unchanged by this feature.
- **FR-011**: The language runtime version MUST be declared consistently across all three locations that pin it, and this consistency MUST be verified as part of the upgrade.

**Job enqueuing behaviour**

- **FR-012**: Every location where a job is enqueued inside a database transaction MUST be identified, including any introduced since the audit was taken.
- **FR-013**: Jobs enqueued within a transaction MUST NOT be processed unless that transaction commits. The post-commit behaviour is adopted; preserving the current pre-commit timing is rejected.
- **FR-014**: A notification to an external system MUST NOT be sent on the basis of a database write that has not committed, and MUST NOT be retried on that basis.
- **FR-015**: The corrected behaviour MUST be verifiable on the current framework version, independently of the version bump, and MUST remain observably identical once the version moves.
- **FR-016**: The rollback path MUST be covered by an explicit test asserting that no partner notification is produced when the surrounding transaction rolls back.

**Execution**

- **FR-017**: The framework version MUST be raised to 7.2 in a step separate from any change to framework defaults, so the two can be verified and reverted independently.
- **FR-018**: The application MUST boot without error in development, test, staging, and production configurations.
- **FR-019**: The full test suite MUST pass with zero failures and no reduction in example count relative to the baseline.
- **FR-020**: Every API namespace MUST return responses equivalent in status and body structure to the recorded 7.1 baseline for the same authenticated request.
- **FR-021**: Authentication, authorization, field-level encryption, serialization, and background job enqueue/execute behaviour MUST be verified as unchanged.
- **FR-022**: Reads and writes against the shared LabSample database MUST produce identical stored values to those produced on 7.1.
- **FR-023**: The upgrade MUST NOT introduce any change to the shared LabSample schema. Any change appearing to require one MUST be escalated for explicit confirmation before proceeding.
- **FR-024**: Deprecation warnings surfaced by the upgrade MUST be either resolved or individually recorded with a rationale for deferring them.
- **FR-025**: Legacy-syntax serialization declarations and deprecated connection-access call sites MUST be migrated to their supported forms or recorded as deliberate deferrals.
- **FR-026**: Configuration differences introduced by 7.2 MUST be reviewed individually and applied deliberately, never adopted wholesale without review.
- **FR-027**: Capabilities introduced by 7.2 that target full-stack rather than API-only applications MUST NOT be adopted, and their exclusion MUST be recorded.
- **FR-028**: The upgrade MUST remain revertible to the exact 7.1.6 dependency set that produced the recorded baseline.

**Defaults adoption**

- **FR-029**: Each new 7.2 framework default MUST carry a recorded adopt-or-override decision with a reason.
- **FR-030**: Any framework default that is overridden rather than adopted MUST be set explicitly with an accompanying explanation.
- **FR-031**: Any defaults change that alters externally visible API behaviour MUST be either reverted or recorded as an intentional documented change.

**Verification and handover**

- **FR-032**: Verification MUST cover behaviour that the automated suite cannot reach — specifically real background-job processing under the production job backend and production-configuration deprecation output. This verification is performed locally against a running worker process; a staging deployment is not required.
- **FR-033**: Job timing behaviour MUST be verified against a real running worker, not only under the in-memory test adapter, since enqueue-timing semantics are exactly the class of change that adapter masks. Both the commit path and the rollback path MUST be exercised deliberately, as neither will be observed incidentally without a deployment soak.
- **FR-034**: The upgrade MUST produce a written record of what changed, what was verified, what was deferred, and how to revert, sufficient for another developer in the ecosystem to act on.

### Key Entities

- **Baseline record**: The measured pre-upgrade state — example count, failure count, runtime, framework and language versions, and resolved dependency set. The reference every later verification compares against.
- **Dependency compatibility verdict**: Per gem — current version, required version for 7.2, verdict, evidence source, and required action.
- **Breaking-change finding**: Per documented 7.2 change — description, priority, whether it applies here, affected locations, and remediation status. Twelve such findings are recorded in the Breaking-Change Audit above.
- **Enqueue-timing decision**: Per location where a job is enqueued inside a transaction — the workflow it belongs to, whether the job must run before or after commit, what happens on rollback, and the resulting action.
- **Framework default decision**: Per new 7.2 default — the default's effect, the adopt-or-override decision, and its rationale.
- **Deferred item**: Anything knowingly not done — what it is, why it was deferred, and what would trigger revisiting it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of gems in the lockfile carry an explicit compatibility verdict; zero gems are unassessed.
- **SC-002**: All 12 documented 7.1→7.2 breaking changes are recorded as either applicable-with-locations or explicitly not-applicable, and all 12 are re-verified at execution time.
- **SC-003**: Zero standard library components remain relied upon at runtime without an explicit dependency declaration.
- **SC-004**: All three locations declaring the language runtime version state the same value.
- **SC-005**: The language runtime version is unchanged by this feature — it remains exactly as recorded in the baseline.
- **SC-006**: Zero external-partner notifications are sent on the basis of an uncommitted database write, verified by an explicit rollback test.
- **SC-007**: The test suite passes with zero failures and no fewer than 737 examples after the upgrade.
- **SC-008**: All eight in-scope API namespaces return responses matching the pre-upgrade baseline in status and body structure; `patient_portal` is excluded as dormant and pending redesign.
- **SC-009**: Every `regspec` write endpoint is covered by at least one smoke check usable for before/after comparison — the namespace goes from zero to non-zero verification coverage.
- **SC-010**: Zero changes to the shared LabSample database schema result from this upgrade.
- **SC-011**: The application boots successfully in all four environment configurations.
- **SC-012**: Every deprecation warning surfaced during the upgrade is either resolved or recorded with a deferral rationale — zero unaddressed warnings.
- **SC-013**: Every new 7.2 framework default has a recorded decision — zero adopted by omission.
- **SC-014**: Zero full-stack-oriented 7.2 capabilities are adopted into this API-only application.
- **SC-015**: Reverting to the pre-upgrade dependency set restores the recorded baseline outcome exactly.
- **SC-016**: Both the commit and rollback paths of the partner-notification workflow are observed against a real running worker before release — neither is left inferred from the test adapter alone.
- **SC-017**: Test suite runtime does not regress by more than 50% relative to the ~36s baseline.
- **SC-018**: A developer unfamiliar with this upgrade can determine from the written record what changed, what was verified, what was deferred, and how to revert — without reading the diff.

## Assumptions

- **Target version is 7.2, not 8.x.** The provided sources are specific to 7.1→7.2, and the official guidance is to upgrade one minor version at a time. Rails 8 is a separate future effort.
- **Ruby stays at 3.3.7 — decided, not assumed.** Raising Ruby to 3.4 alongside Rails was explicitly considered and rejected for this feature: changing one variable at a time keeps failure attribution and rollback unambiguous, Ruby 3.3 is supported well past this work, and Rails 7.2 supports 3.4 so nothing is foreclosed by waiting. Ruby 3.4 is expected to follow as a separate feature.
- **The `csv`/`base64` declaration is in scope despite originating from the Ruby 3.4 evaluation.** It fixes a latent defect that exists independently of either upgrade, is safe on the current runtime, and removes a blocker from the future Ruby work. Including it here is cheaper than carrying it forward.
- **Making implicit dependencies explicit is not the same as upgrading them.** The intent is to declare what is already in use, pinned so behaviour does not change. Selecting deliberately newer versions is out of scope.
- **Latest 7.1 patch first.** The application is on 7.1.6; if a newer 7.1 patch exists, moving to it and confirming green precedes the 7.2 bump.
- **Scope is this application only.** Other Masdiag apps sharing the LabSample database are not upgraded here, though the API-response equivalence requirement exists to protect them.
- **Verification rests on the existing RSpec suite plus targeted manual checks.** With no CI configured, verification is local; adding CI is out of scope but would strengthen it and is worth noting as a follow-up.
- **Non-schema-changing dependency and configuration changes are in scope.** Anything touching the shared LabSample schema is not, per the ecosystem rule that such changes need explicit confirmation.
- **Refactoring, feature work, and performance tuning are out of scope.** Only changes required by the upgrade or by a documented 7.2 behaviour change are included. The two remaining legacy-syntax enum declarations are addressed only if 7.2 actually requires it.
- **Dual-boot tooling is optional.** It is a means, not a requirement; the spec mandates that the version bump and defaults flip be independently verifiable and revertible, and leaves the mechanism to planning.
- **Blocking is an acceptable outcome.** If a dependency has no 7.2-compatible release, reporting the blocker is a successful result for Story 1; forcing the upgrade past it is not.
- **The Breaking-Change Audit is a planning input, not finished work.** It was produced by scanning the working tree on 2026-08-17 and records where remediation is likely needed. It does not constitute remediation, and its findings expire as the codebase changes.
- **Post-commit job enqueuing is decided, not open.** Clarified 2026-08-17: jobs enqueued inside a transaction run only if that transaction commits. Preserving the current pre-commit timing was considered and rejected, because the one affected site notifies an external partner and retries, so pre-commit timing produces a durable inconsistency with no compensating action. Opting out — globally or at the call site — is therefore out of scope rather than a permitted fallback.
- **Fixing the code does not repair history.** Any partner notification already sent for an assignment that later rolled back is inconsistent today. Whether such records exist and need reconciling is a data question for the business, outside this upgrade.
- **The audit's "not applicable" findings still get re-verified.** Six of the 12 changes currently have no occurrences; that is a reason to spend little time on them, not a reason to skip the confirming scan, which is cheap.
- **Full-stack 7.2 features are excluded on architectural grounds.** Browser-version guards, PWA scaffolding, and DevContainers are irrelevant to an API-only application. DevContainers could be adopted independently as a developer-experience improvement, but that is separate work, not part of this upgrade.
