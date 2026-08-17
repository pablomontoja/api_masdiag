---
description: "Task list for Rails 7.2 upgrade"
---

# Tasks: Rails 7.2 Upgrade

**Input**: Design documents from `/specs/007-rails-72-upgrade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-equivalence.md, quickstart.md

**Tests**: Test tasks ARE included. Constitution Principle III (Test-First) is NON-NEGOTIABLE, and the spec explicitly requires a rollback test (FR-016, SC-006) and `regspec` smoke checks (SC-009), both written *before* the version bump.

**Organization**: Grouped by user story. Note the unusual shape of this feature — **US1, US2 and US3 all execute on Rails 7.1** and each delivers value even if the upgrade is abandoned. The framework bump itself does not occur until US4.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- All paths are repository-relative from `/home/pswider/rails/api_masdiag`

## Critical execution rules

1. **Never run a bare `bundle update`.** It resolves but sweeps in ~40 unrelated bumps (rspec-rails 7→8, sentry 5→6), destroying failure attribution and the rollback guarantee. Use the exact commands given.
2. **`regspec` smoke checks and the rollback spec must exist and pass BEFORE T023 (the version bump).** Written afterwards they document post-upgrade behaviour and prove nothing.
3. **Stop at any failed gate.** Revert that step rather than proceeding with a partial state.
4. Every task runs under `rvm use 3.3.7`.

---

## Phase 1: Setup (Baseline Capture)

**Purpose**: Establish the reference every later verification compares against.

- [X] T001 Run `rvm use 3.3.7 && bundle exec rspec` and record example count, failure count, and runtime in `specs/007-rails-72-upgrade/baseline.md` (expect 737 examples, 0 failures, ~36s)
- [X] T002 Copy `Gemfile.lock` to `specs/007-rails-72-upgrade/baseline-Gemfile.lock` and record the current `git rev-parse HEAD` in `specs/007-rails-72-upgrade/baseline.md`
- [X] T003 [P] Record Rails version, Ruby version, and `config.load_defaults` value (from `config/application.rb:24`) in `specs/007-rails-72-upgrade/baseline.md`
- [X] T004 [P] Verify the Ruby version pin agrees across all three locations — `.ruby-version`, `Gemfile` line 4, and `Dockerfile` `ARG RUBY_VERSION` — and record in `specs/007-rails-72-upgrade/baseline.md`

**Gate**: Suite is green and a rerun reproduces the same outcome. **If the suite is not green, stop here** — every later comparison depends on this reference.

---

## Phase 2: Foundational (Audit Re-Verification)

**Purpose**: The Breaking-Change Audit in `spec.md` is a snapshot from 2026-08-17; line numbers drift (FR-007). Confirm it before acting on it.

**⚠️ BLOCKING**: No remediation may begin until the audit is re-verified.

- [X] T005 [P] Re-scan changes with no expected occurrences and record results in `specs/007-rails-72-upgrade/audit-verification.md`: `grep -rn "alias_attribute" app/ lib/ config/`, `grep -rn "Rails.application.secrets" app/ lib/ config/`, `grep -rn "check_pending" spec/ config/ lib/`, `grep -rn "query_constraints" app/ lib/`, `grep -rnE "params\s*==" app/ spec/`
- [X] T006 [P] Re-verify `config/environments/test.rb` still sets `show_exceptions` to `:rescuable` and that no boolean values exist anywhere in `config/environments/`
- [X] T007 [P] Re-locate the positional-coder `serialize` site (expected `app/models/key_value_db_store.rb:5`) and the three `ActiveRecord::Base.connection` sites (expected `db/migrate/20260311113835_toxicology_quant_project.rb` ×2 and `spec/services/hl7/measurement_importer_spec.rb`); record exact current line numbers
- [X] T008 Re-run the in-transaction enqueue scan and confirm `app/controllers/fv1/kit_controller.rb` is still the only hit: `for f in $(grep -rl "perform_later\|deliver_later" app/ lib/); do grep -q "transaction do\|transaction(" "$f" && echo "$f"; done`, then inspect each result to confirm whether the enqueue is inside or after the transaction block
- [X] T009 Record any newly-introduced in-transaction enqueue site in `specs/007-rails-72-upgrade/audit-verification.md` as an additional E4 decision record, following the data-model.md E4 schema

**Checkpoint**: All 12 audit entries confirmed or corrected. User story work may now begin.

---

## Phase 3: User Story 2 — Declare stdlib dependencies (Priority: P1) 🎯 MVP

**Goal**: Declare `csv` and `base64` explicitly so the application states what it actually needs. Fixes a latent defect on scheduled-report paths and removes a blocker from the future Ruby 3.4 work.

**Independent Test**: On Rails 7.1, declare both gems, confirm the lockfile gains only `csv` and the suite stays green. Delivers value with no relation to the framework upgrade.

**Why this is the MVP**: it is the only task group that fixes an existing defect rather than enabling an upgrade, and it has near-zero blast radius (verified in research R5: exactly one lockfile line changes).

- [X] T010 [US2] Add `gem "csv"` and `gem "base64"` to `Gemfile` immediately after the `rails` gem line, each with a comment naming why (required by application code; not Ruby default gems from 3.4)
- [X] T011 [US2] Run `bundle lock` — **plain resolution, NOT `--conservative --update`**, which cannot add gems absent from the lockfile
- [X] T012 [US2] Verify via `git diff Gemfile.lock` that the diff adds only `csv (3.3.6)`, that `base64 (0.3.0)` was already present transitively, and that `rails` remains `7.1.6`
- [X] T013 [US2] Run `bundle exec rspec` and confirm the baseline result from T001 is reproduced exactly
- [X] T014 [US2] Commit as a standalone change, with a message noting it is independent of the Rails upgrade

**Checkpoint**: US2 complete and shippable on its own. `csv`/`base64` are declared; Rails is untouched.

---

## Phase 4: User Story 3 — Fix partner-notification timing (Priority: P2)

**Goal**: Ensure the external partner (Lalen/FFTB, institution 83) is never told about a kit assignment that was not persisted. Currently a rolled-back transaction still notifies the partner and retries up to 10 times.

**Independent Test**: On Rails 7.1, force a rollback in the kit-assignment flow and confirm no job is enqueued; confirm a successful assignment still enqueues exactly one.

**⚠️ Test-First is mandatory here** (Constitution III): T015 must fail before T017 makes it pass.

- [X] T015 [US3] Write failing spec `spec/requests/fv1/kit_assignment_rollback_spec.rb` asserting that when the assignment transaction rolls back, **no** `LalenApi::AssignKitTestsJob` is enqueued. Use `POST /fv1/kits/assign_tests` with `http_auth_header`, an institution with `id: 83` (FFTB), a `reserved_sample_code` with `InstitutionId: 83`, and test_ids that map to `V1::Common::LALEN_TEST_API_KEYS`. Force rollback by stubbing `@current_rsc.update!` to raise `ActiveRecord::Rollback` or by making a `reserved_tests.create!` fail. Follow the `let!` factory style of `spec/requests/fv1_kit_assign_spec.rb`
- [X] T016 [US3] Run the new spec and confirm it **fails because the job IS enqueued** — verify the failure message, not merely that it is red. A setup error is not a valid RED state
- [X] T017 [US3] In `app/controllers/fv1/kit_controller.rb`, move the `assign_tests_in_lalen_api` call (currently line 45) from inside the transaction to after the block's closing `end` (currently line 46), adding a brief comment explaining that the partner must only be notified once the write has committed
- [X] T018 [US3] Run `spec/requests/fv1/kit_assignment_rollback_spec.rb` and confirm it now passes
- [X] T019 [US3] Add a companion example to the same file asserting the **commit** path still enqueues exactly one job, so the fix cannot regress into "never notifies"
- [X] T020 [US3] Run `bundle exec rspec spec/requests/fv1_kit_assign_spec.rb` to confirm the existing kit-assignment specs still pass
- [X] T021 [US3] Run the full `bundle exec rspec` — still on Rails 7.1 — and confirm the baseline is reproduced with the new examples added
- [X] T022 [US3] Commit as a standalone defect fix, with a message noting it is independent of the Rails upgrade

**Checkpoint**: US3 complete on Rails 7.1. The defect is fixed and verified before the framework moves.

---

## Phase 5: User Story 4 — Run on Rails 7.2 (Priority: P3)

**Goal**: Move the framework to 7.2.3 while keeping `load_defaults` at 7.1, so the version bump and the defaults change fail independently.

**Independent Test**: Boot all four environments, run the full suite, and confirm the eight in-scope namespaces return equivalent responses.

### Pre-bump verification coverage (MUST precede T026)

- [X] T023 [P] [US4] Create `spec/requests/regspec/institutions_spec.rb` — smoke coverage for `POST /regspec/institutions` and `PATCH /regspec/institutions/:id`. All regspec controllers `include MasdiagCheck`, so use an `api_account` whose contractor belongs to `institution` with `id: 1`. One success path and one auth-failure path each; assert status and body shape only
- [X] T024 [P] [US4] Create `spec/requests/regspec/contractors_spec.rb` — same pattern for `POST /regspec/contractors` and `PATCH /regspec/contractors/:id`
- [X] T025 [P] [US4] Create `spec/requests/regspec/samples_spec.rb` — same pattern for `POST /regspec/samples` and `PATCH /regspec/samples/:id`
- [X] T026 [P] [US4] Create `spec/requests/regspec/patients_spec.rb` — same pattern for `PATCH /regspec/patients/:id`
- [X] T027 [US4] Run `bundle exec rspec spec/requests/regspec/` on **Rails 7.1** and confirm all new specs pass. This captures the before-state required by `contracts/api-equivalence.md`
- [X] T028 [US4] Commit the regspec smoke checks separately, before any dependency change

### The version bump

- [X] T029 [US4] In `Gemfile`, change `gem "rails", "~> 7.1.5", ">= 7.1.5.1"` to `gem "rails", "~> 7.2.3"`, and change `gem "lockbox", "~> 1.2.0"` to `gem "lockbox", "~> 2.2.0"`. **Replace the obsolete comment** `# Lockbox >= 2.2 refuses to load on Active Record 7.1` with one stating that Lockbox 2.2.0 requires Active Record >= 7.2 (the gem's guard is `if ar_version < 7.2 → raise`, see research.md R2)
- [X] T030 [US4] Run `bundle lock --conservative --update rails lockbox` — **never a bare `bundle update`**
- [X] T031 [US4] Verify via `git diff Gemfile.lock` that only the Rails stack moves to 7.2.3, `lockbox` to 2.2.0, and `useragent` is added as a new transitive dependency. **Explicitly confirm `rspec-rails` is still 7.1.1, `solid_queue` still 1.4.0, and sentry still on 5.x.** If anything else moved, revert and re-run with the correct flags
- [X] T032 [US4] Run `bundle install`

### Verification

- [X] T033 [US4] Boot each environment and confirm no errors: `for env in development test staging production; do RAILS_ENV=$env bin/rails runner 'puts "#{Rails.env}: #{Rails.version}"'; done`
- [X] T034 [US4] Run `bin/rails db:migrate RAILS_ENV=test` and confirm no schema change is produced — `git diff db/schema.rb` must be empty (FR-023, SC-010)
- [X] T035 [US4] Run the full `bundle exec rspec` and confirm zero failures with no reduction in example count relative to T001
- [X] T036 [US4] Verify Lockbox 2.2.0 decrypts data written under 1.2.0: `bin/rails runner 'a = ApiAccount.where.not(settings: nil).first; puts a ? a.settings.inspect : "none"'`. A major version bump on the library protecting patient data must be confirmed, not inferred from a green suite
- [X] T037 [US4] Compare responses for the eight in-scope namespaces against the T001 baseline per `contracts/api-equivalence.md`; record results in `specs/007-rails-72-upgrade/equivalence-report.md`. `patient_portal` is excluded as dormant

### Deprecation cleanup

- [X] T038 [P] [US4] In `app/models/key_value_db_store.rb:5`, change `serialize :json, ::ActiveRecord::Coders::JSON` to the keyword form `serialize :json, coder: ::ActiveRecord::Coders::JSON`
- [X] T039 [P] [US4] Replace `ActiveRecord::Base.connection.execute(...)` with `ActiveRecord::Base.with_connection { |conn| conn.execute(...) }` at both sites in `db/migrate/20260311113835_toxicology_quant_project.rb` (~lines 229, 233). This is a historical migration — verify it still runs on a fresh database rather than assuming
- [X] T040 [P] [US4] Apply the same `with_connection` replacement in `spec/services/hl7/measurement_importer_spec.rb` (~line 57)
- [X] T041 [US4] Run `bundle exec rspec 2>&1 | grep -i "deprecat" | sort -u` and either resolve each remaining warning or record it with a deferral rationale in `specs/007-rails-72-upgrade/deprecations.md` (FR-024, SC-012)

### Real-worker verification

- [X] T042 [US4] Start a real worker with `bin/rails solid_queue:start` in a separate terminal. The test environment's in-memory `:test` adapter cannot demonstrate post-commit timing (FR-033)
- [X] T043 [US4] Exercise the FFTB kit-assignment flow with a **committing** transaction and confirm the partner notification job runs exactly once
- [X] T044 [US4] Exercise the same flow forcing a **rollback** and confirm no job is enqueued and no retries occur. With no staging soak, this path is only ever exercised deliberately (SC-016)
- [X] T045 [US4] Record both observations in `specs/007-rails-72-upgrade/equivalence-report.md`
- [X] T046 [US4] Commit the upgrade

**Checkpoint**: The application runs on Rails 7.2.3 with 7.1 defaults — a legitimate, shippable end state. US5 is optional from here.

---

## Phase 6: User Story 1 — Assessment record (Priority: P1, completed incrementally)

**Goal**: Produce the written compatibility and audit record that makes the upgrade auditable and reversible.

**Note on ordering**: US1 is P1 but its artifacts are *populated* by the work above. Phase 0 research already resolved the compatibility verdicts (the graph resolves; no blockers); these tasks consolidate that evidence into the deliverable required by FR-034.

- [X] T047 [P] [US1] Write `specs/007-rails-72-upgrade/compatibility-report.md` recording the E2 verdict table from `data-model.md`: Rails stack → 7.2.3, `lockbox` → 2.2.0 (forced), `csv`/`base64` newly declared, `useragent` new transitive, ~160 gems unchanged, **zero blocking**
- [X] T048 [P] [US1] Record in the same report that the git-sourced `k-php-serialize` gem resolved cleanly despite being unassessable by automated tooling (FR-003)
- [X] T049 [P] [US1] Record the lockbox finding explicitly: the pin did not merely lift, it inverted — 2.2.0 requires Active Record >= 7.2, so the Gemfile comment was obsolete rather than a blocker (FR-004)
- [X] T050 [US1] Consolidate `audit-verification.md` into the final record, marking each of the 12 breaking changes with its status: not-applicable / already-compliant / remediated
- [X] T051 [US1] Write the handover summary in `specs/007-rails-72-upgrade/upgrade-record.md`: what changed, what was verified, what was deferred, and the exact revert procedure (FR-034, SC-018)

**Checkpoint**: The upgrade is auditable by another developer without reading the diff.

---

## Phase 7: User Story 5 — Adopt 7.2 framework defaults (Priority: P4, optional)

**Goal**: Reduce configuration debt by reviewing each new 7.2 default individually.

**Deferrable**: An application on 7.2 with 7.1 defaults is supported and shippable. This phase may be postponed without blocking anything above.

- [X] T052 [US5] Run `bin/rails app:update` and review every hunk individually. Accept nothing blindly — this generates a full-stack scaffold diff against an API-only application
- [X] T053 [US5] Explicitly decline the full-stack additions and record the decision in `specs/007-rails-72-upgrade/defaults-decisions.md`: browser-version guard (`allow_browser`), PWA scaffolding (`app/views/pwa/`), and DevContainer configuration (FR-027, SC-014)
- [X] T054 [US5] Enumerate each new 7.2 framework default from the generated `config/initializers/new_framework_defaults_7_2.rb` and record an adopt-or-override decision with rationale for each, per the E5 schema in `data-model.md` (FR-029, SC-013)
- [X] T055 [US5] Change `config.load_defaults 7.1` to `7.2` in `config/application.rb:24`
- [X] T056 [US5] Run `bundle exec rspec` and confirm zero failures
- [X] T057 [US5] Re-run the namespace equivalence comparison from T037; if any default alters externally visible API behaviour, either override it explicitly with a comment or record it as an intentional documented change (FR-030, FR-031)
- [X] T058 [US5] Commit the defaults adoption separately from the version bump, so the two can be reverted independently

---

## Phase 8: Polish & Cross-Cutting

- [X] T059 [P] Confirm the Ruby version is still 3.3.7 and still consistent across `.ruby-version`, `Gemfile`, and `Dockerfile` — the upgrade must not have drifted it (FR-010, FR-011, SC-005)
- [X] T060 [P] Confirm `git diff db/schema.rb` is empty for the whole feature branch — zero LabSample schema change (FR-023, SC-010)
- [X] T061 [P] Confirm suite runtime has not regressed more than 50% versus the ~36s baseline (SC-017)
- [X] T062 Verify the revert procedure actually works: `git checkout main -- Gemfile Gemfile.lock && bundle install && bundle exec rspec`, confirm the baseline reproduces exactly, then restore the branch state (FR-028, SC-015)
- [X] T063 Update `CLAUDE.md` if any documented convention changed as a result of the upgrade (e.g. the Rails version stated in the project overview)

---

## Dependencies & Execution Order

```
Phase 1 (Setup: T001–T004)
        ↓
Phase 2 (Foundational audit: T005–T009)   ⚠️ BLOCKING
        ↓
        ├─→ Phase 3 (US2: T010–T014)  ── independent, Rails 7.1 ── SHIPPABLE
        │           ↓
        ├─→ Phase 4 (US3: T015–T022)  ── independent, Rails 7.1 ── SHIPPABLE
        │           ↓
        └─→ Phase 5 (US4: T023–T046)  ── the actual upgrade
                    │
                    │  T023–T028 (regspec specs) MUST precede T029 (bump)
                    ↓
            Phase 6 (US1 record: T047–T051)
                    ↓
            Phase 7 (US5 defaults: T052–T058)  ── optional
                    ↓
            Phase 8 (Polish: T059–T063)
```

**Story dependencies**:

- **US2** (T010–T014): fully independent. Could ship today.
- **US3** (T015–T022): independent of US2; both run on Rails 7.1. Sequence them to keep commits attributable.
- **US4** (T023–T046): depends on US3 being complete (the fix must be verified pre-bump) and benefits from US2 being done.
- **US1** (T047–T051): consolidates evidence produced by the phases above.
- **US5** (T052–T058): depends on US4. Optional.

**Hard ordering constraints** (violating these invalidates the verification):

1. T023–T027 (`regspec` specs) **before** T029 (version bump) — otherwise no before-state exists.
2. T015–T016 (failing spec) **before** T017 (the fix) — Constitution III.
3. T001 (baseline) **before** everything — nothing is comparable without it.

## Parallel Execution Opportunities

**Phase 2** — T005, T006, T007 touch different scan targets and can run together.

**Phase 5 pre-bump** — T023, T024, T025, T026 create four separate spec files with no shared state:

```
T023 spec/requests/regspec/institutions_spec.rb
T024 spec/requests/regspec/contractors_spec.rb
T025 spec/requests/regspec/samples_spec.rb
T026 spec/requests/regspec/patients_spec.rb
```

**Phase 5 cleanup** — T038, T039, T040 touch three different files.

**Phase 6** — T047, T048, T049 write to distinct sections of the compatibility report.

**Phase 8** — T059, T060, T061 are independent read-only verifications.

## Implementation Strategy

### MVP (recommended first delivery)

**Phase 1 + Phase 2 + Phase 3 (US2)** — T001 through T014. Fixes a real latent defect on scheduled-report paths, ships independently, and removes a blocker from the future Ruby 3.4 work. Roughly one lockfile line of risk.

### Second increment

**Phase 4 (US3)** — T015 through T022. Fixes the partner-notification data-consistency defect, still on Rails 7.1. Also independently valuable.

### Third increment

**Phase 5 (US4)** — T023 through T046. The upgrade proper. By this point both latent defects are already fixed and verified, so any failure here is attributable to the framework change alone.

### Optional

**Phase 7 (US5)** — defaults adoption, deferrable indefinitely.

## Task Summary

| Phase | Story | Tasks | Count |
|-------|-------|-------|-------|
| 1 Setup | — | T001–T004 | 4 |
| 2 Foundational | — | T005–T009 | 5 |
| 3 | US2 (P1) 🎯 | T010–T014 | 5 |
| 4 | US3 (P2) | T015–T022 | 8 |
| 5 | US4 (P3) | T023–T046 | 24 |
| 6 | US1 (P1) | T047–T051 | 5 |
| 7 | US5 (P4) | T052–T058 | 7 |
| 8 Polish | — | T059–T063 | 5 |
| **Total** | | | **63** |

**Parallel opportunities**: 18 tasks marked `[P]`.

**Independent test criteria**:

- **US2**: lockfile gains only `csv`; suite green on Rails 7.1.
- **US3**: rolled-back assignment enqueues no job; committed assignment enqueues exactly one — verified on Rails 7.1.
- **US4**: four environments boot; suite green with ≥737 examples; eight namespaces equivalent; schema unchanged.
- **US1**: every gem carries a verdict; all 12 breaking changes have a status; revert procedure demonstrated.
- **US5**: every new default carries an adopt-or-override decision; suite green.
