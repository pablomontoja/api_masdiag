---
description: "Task list for Ruby 3.4 upgrade"
---

# Tasks: Ruby 3.4 Upgrade

**Input**: Design documents from `/specs/008-ruby-34-upgrade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/runtime-compatibility.md, quickstart.md

**Tests**: Test tasks ARE included, but they differ in character from spec 007. This feature adds **no new behaviour**, so there is nothing to drive with a failing test (Constitution III is satisfied by the existing 755-example suite being the specification of correct behaviour). The test tasks here are **verification instruments** that must be written *before* the runtime changes in order to capture a genuine before-state — specifically the cross-runtime encryption probe.

**Organization**: Grouped by user story. Steps in Phases 1–3 run on **Ruby 3.3.7** and are valuable even if the runtime change is abandoned.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- All paths are repository-relative from `/home/pswider/rails/api_masdiag`

## Critical execution rules

1. **Target is Ruby 3.4.10, not the sandbox trial's 3.4.9.** A newer patch published since the trial (research R1). The trial's evidence carries forward but is not the verification.
2. **Never run `bundle update`.** The lockfile must be *regenerated* for the new `RUBY VERSION` stanza, not re-resolved. The trial used an unconstrained update and pulled ~20 unrelated gems.
3. **`observer` must be declared BEFORE the runtime changes** — `bundle lock --conservative --update` cannot add a gem absent from the lockfile (research R5).
4. **The encryption probe must be written and persisted BEFORE the runtime changes** — a round-trip performed entirely on the new runtime proves nothing about cross-runtime compatibility.
5. **Stop at any failed gate.** Revert that step rather than proceeding with a partial state.
6. **No file under `app/`, `lib/`, `config/` or `db/` should change.** If one appears to need changing, that is a compatibility problem the trial did not surface — investigate, do not absorb.

---

## Phase 1: Setup (Baseline Capture on Ruby 3.3.7)

**Purpose**: Establish the reference every later verification compares against.

- [X] T001 Run `rvm use 3.3.7 && bundle exec rspec` and record example count, failure count, and runtime in `specs/008-ruby-34-upgrade/baseline.md` (expect 755 examples, 0 failures, ~35s)
- [X] T002 Copy `Gemfile.lock` to `specs/008-ruby-34-upgrade/baseline-Gemfile.lock`, record its sha256 and the current `git rev-parse HEAD` in `specs/008-ruby-34-upgrade/baseline.md`
- [X] T003 [P] Record the Ruby version from all four sources in `specs/008-ruby-34-upgrade/baseline.md`: `.ruby-version`, `Gemfile:4`, `Dockerfile:4`, and the `RUBY VERSION` stanza at `Gemfile.lock:532`
- [X] T004 [P] Record the Rails version (`7.2.3`) and `config.load_defaults` (`7.2`) in `specs/008-ruby-34-upgrade/baseline.md` as the values that MUST NOT change (FR-013, SC-007)

**Gate**: Suite green and a rerun reproduces the same outcome. **If the suite is not green, stop** — every later comparison depends on this reference.

---

## Phase 2: Foundational (Dependency Audit)

**Purpose**: The sandbox trial found `observer` to be the only blocker. FR-002 requires confirming that rather than trusting it, because dependencies may have moved since.

**⚠️ BLOCKING**: The runtime must not change until this audit is complete.

- [X] T005 Scan application and test code for standard library requires and record results in `specs/008-ruby-34-upgrade/stdlib-audit.md`: for each of `observer ostruct bigdecimal drb logger benchmark mutex_m abbrev syslog getoptlong nkf fiddle`, count `grep -rE "require .<gem>." app/ lib/ config/ spec/` and check whether it is declared in `Gemfile`
- [X] T006 Scan installed gems for internal requires of removed default gems — `grep -rln "require ['\"]observer['\"]" $(bundle show --paths | head -60)` — and record which dependencies force a declaration
- [X] T007 Record the E2 finding table in `specs/008-ruby-34-upgrade/stdlib-audit.md` per the `data-model.md` schema, marking each component `already-declared` / `needs-declaration` / `confirmed-unused`

**Checkpoint**: Every stdlib component is declared or confirmed unused. User story work may begin.

---

## Phase 3: User Story 1 — Declare the last stdlib dependency (Priority: P1) 🎯 MVP

**Goal**: Declare `observer` explicitly so the application states what it requires rather than depending on what the runtime bundles.

**Independent Test**: Declare it on Ruby 3.3.7, confirm the lockfile gains only `observer` and the suite still passes. Delivers value as completed hygiene even if the runtime change never happens.

**Why this is the MVP**: it is the entire blocker. Without it the application fails at boot on Ruby 3.4 with `cannot load such file -- observer` — the single cause of all 97 load errors in the trial. It also completes work begun in spec 007, which declared `csv` and `base64` and left this one recorded as outstanding.

- [X] T008 [US1] Add `gem "observer"` to `Gemfile` immediately after line 13 (`gem "base64"`), with the comment `# required by factory_bot 4.11; not a Ruby default gem from 3.4`, keeping all three stdlib declarations together (FR-001, SC-001)
- [X] T009 [US1] Run `bundle lock` — **plain resolution, NOT `--conservative --update`**, which cannot add a gem absent from the lockfile
- [X] T010 [US1] Verify via `git diff Gemfile.lock` that the diff adds **only** `observer` (one line in `GEM`, one in `DEPENDENCIES`), that `rails` remains `7.2.3`, and that no other gem version moved
- [X] T011 [US1] Run `bundle exec rspec` and confirm the T001 baseline is reproduced exactly, demonstrating the declaration changes no behaviour on the current runtime (FR-003)
- [X] T012 [US1] Commit as a standalone change, noting it ships independently of the runtime upgrade

**Checkpoint**: US1 complete and shippable on its own. The Ruby 3.4 blocker is removed while still on 3.3.7.

---

## Phase 4: User Story 2 — Run on the new language runtime (Priority: P2)

**Goal**: Raise the runtime to 3.4.10 and confirm nothing observable changes.

**Independent Test**: Switch the runtime, reinstall, run the suite and exercise the API. Success is that nothing changes except the version number.

### Pre-change verification instruments (MUST precede T017)

- [X] T013 [US2] Create `spec/models/encryption_round_trip_spec.rb` asserting that `ApiAccount#settings` (declared `has_encrypted :settings, type: :hash`) round-trips correctly and that `settings_ciphertext` never contains the plaintext. Follow the `let!`/factory style of existing specs in `spec/models/`
- [X] T014 [US2] Run the new spec on Ruby 3.3.7 and confirm it passes — this is the before-state for FR-011
- [X] T015 [US2] Persist a probe record in the development database whose ciphertext can be read back after the runtime change: `bin/rails runner` creating an `ApiAccount` with `username: "enc_probe_008"` and `settings = { probe: "pre-ruby-34" }`, recording its id in `specs/008-ruby-34-upgrade/baseline.md`
- [X] T016 [US2] Commit the encryption spec separately, before any runtime change

### The runtime change

- [X] T017 [US2] Refresh RVM's known-list with `rvm get stable` — it is stale on this workstation (`rvm list known | grep 3.4` returns nothing), so `rvm install 3.4.10` fails without it
- [X] T018 [US2] Install and select the runtime: `rvm install 3.4.10 && rvm use 3.4.10`, then confirm `ruby -v` reports `3.4.10` (FR-004)
- [X] T019 [P] [US2] Set `.ruby-version` to `ruby-3.4.10`
- [X] T020 [P] [US2] Change `Gemfile:4` from `ruby "3.3.7"` to `ruby "3.4.10"`
- [X] T021 [P] [US2] Change `Dockerfile:4` from `ARG RUBY_VERSION=3.3.7` to `ARG RUBY_VERSION=3.4.10`
- [X] T022 [US2] Verify all three pins agree: `cat .ruby-version; grep '^ruby ' Gemfile; grep 'ARG RUBY_VERSION' Dockerfile` (FR-005, SC-006)
- [X] T023 [US2] Run `bundle install` on the new runtime — **never `bundle update`**. This regenerates the `RUBY VERSION` stanza rather than re-resolving the graph
- [X] T024 [US2] Verify all 11 source-compiled gems built: `mysql2`, `bcrypt`, `oj`, `bootsnap`, `msgpack`, `puma`, `json`, `racc`, `date`, `prawn`, `caxlsx` (FR-006, SC-003)
- [X] T025 [US2] Verify the 2 precompiled gems resolved a binary matching the new runtime rather than falling back to source: check the platform suffix on the `ffi` and `nokogiri` lines in `Gemfile.lock`. Their failure mode is a *missing variant*, not a compilation error, so it will not surface as a build failure (FR-006, SC-003, see `data-model.md` E3)
- [X] T026 [US2] Verify containment via `git diff Gemfile.lock`: the diff must show only the `RUBY VERSION` stanza and platform-variant lines for `ffi`/`nokogiri`. **Any other gem version movement means stop and investigate** (FR-007, SC-008)

### Verification

- [X] T027 [US2] Run `bin/rails db:migrate RAILS_ENV=test`, then confirm `git diff db/schema.rb` is **empty** — a Ruby change must not touch the schema (FR-010, SC-005)
- [X] T028 [US2] Run the full `bundle exec rspec` and confirm zero failures with no reduction in example count relative to T001 (FR-008, SC-002)
- [X] T029 [US2] Run each in-scope namespace's specs per `contracts/runtime-compatibility.md` and record results in `specs/008-ruby-34-upgrade/equivalence-report.md`: `v1` (spec/requests/api), `fv1`, `nume`, `lalen`, `masdiag`, `masdiag_mailer`, `regspec`, `webhook`. `patient_portal` is excluded as dormant (FR-009, SC-004)
- [X] T030 [US2] Read back the T015 probe record on Ruby 3.4.10 and confirm the value written on 3.3.7 decrypts correctly and the ciphertext remains opaque (FR-011, SC-010)
- [X] T031 [US2] Start a real worker with `bin/rails solid_queue:start` — `solid_queue_db` now exists locally, so real-adapter verification is possible without the remote host
- [X] T032 [US2] Exercise the FFTB kit-assignment flow with a committing transaction and confirm exactly one `LalenApi::AssignKitTestsJob` is enqueued (FR-012)
- [X] T033 [US2] Exercise the same flow forcing a rollback and confirm no job is enqueued, preserving the post-commit semantics established in spec 007 (FR-012, FR-019)
- [X] T034 [US2] Build the container image: `docker build --build-arg RUBY_VERSION=3.4.10 -t api_masdiag:ruby34 .` and confirm all source-compiled gems build inside `ruby:3.4.10-slim`, whose toolchain differs from the workstation's (FR-014, SC-003, SC-011)
- [X] T035 [US2] Review warnings via `bundle exec rspec 2>&1 | grep -iE "warning|deprecat" | sort -u` and record each as resolved or deferred in `specs/008-ruby-34-upgrade/warnings.md` (FR-015, SC-009)
- [X] T036 [US2] Commit the runtime change

**Checkpoint**: The application runs on Ruby 3.4.10 with Rails unchanged at 7.2.3.

---

## Phase 5: User Story 3 — Assess the outdated test dependency (Priority: P3, optional)

**Goal**: Decide whether `factory_bot` should be upgraded so the `observer` declaration can eventually be retired, rather than carried indefinitely without explanation.

**Deferrable**: Not required for the runtime change. Recorded so the compatibility declaration does not become a permanent unexplained workaround.

- [X] T037 [US3] Compare `factory_bot` 4.11.1 against the current 6.x line and record the breaking changes affecting this codebase's factory definitions in `specs/008-ruby-34-upgrade/factory-bot-assessment.md`
- [X] T038 [US3] Record an upgrade-now or defer-with-reason decision in the same file (FR-017)
- [X] T039 [US3] If deferring, extend the `Gemfile` comment on `gem "observer"` to state what would permit its removal — an upgrade past factory_bot 4.x (FR-018)

---

## Phase 6: Polish & Cross-Cutting

- [X] T040 [P] Confirm Rails is still `7.2.3` and `config.load_defaults` is still `7.2` — the framework must not have moved (FR-013, SC-007)
- [X] T041 [P] Confirm `git diff main...HEAD --stat db/schema.rb` is empty for the whole branch (SC-005)
- [X] T042 [P] Confirm suite runtime has not regressed more than 50% versus the T001 baseline (SC-013)
- [X] T043 Verify the revert procedure works: `rvm use 3.3.7 && git checkout main -- Gemfile Gemfile.lock .ruby-version Dockerfile && bundle install && bundle exec rspec`, confirm the baseline reproduces, then restore the branch state. **Revert the runtime and files together** — spec 007 showed that reverting only the lockfile leaves a broken tree (FR-016, SC-012)
- [X] T044 Write the handover record in `specs/008-ruby-34-upgrade/upgrade-record.md`: what changed, what was verified, what was deferred, and how to revert (FR-020, SC-014)
- [X] T045 Remove the T015 probe record from the development database once verification is complete

---

## Dependencies & Execution Order

```
Phase 1 (Baseline: T001–T004)  ── on Ruby 3.3.7
        ↓
Phase 2 (Stdlib audit: T005–T007)   ⚠️ BLOCKING
        ↓
Phase 3 (US1: T008–T012)  ── on Ruby 3.3.7 ── SHIPPABLE ALONE
        ↓
Phase 4 (US2: T013–T036)
        │
        │  T013–T016 (encryption probe) MUST precede T017 (runtime install)
        │  T008–T012 (observer)         MUST precede T024 (bundle install on 3.4)
        ↓
Phase 5 (US3: T037–T039)  ── optional
        ↓
Phase 6 (Polish: T040–T045)
```

**Story dependencies**:

- **US1** (T008–T012): fully independent. Ships today on Ruby 3.3.7.
- **US2** (T013–T036): depends on US1 — without the `observer` declaration, `bundle install` on 3.4.10 fails at boot.
- **US3** (T037–T039): depends on US2 conceptually (it is about retiring US1's workaround), but could run any time. Optional.

**Hard ordering constraints** (violating these invalidates the verification):

1. **T008–T012 before T024** — `--conservative --update` cannot add a gem, so `observer` needs its own plain-resolution commit on the old runtime.
2. **T013–T015 before T017** — the encryption probe must be written and persisted on Ruby 3.3.7, or it proves nothing about cross-runtime compatibility.
3. **T001 before everything** — nothing is comparable without the baseline.

## Parallel Execution Opportunities

**Phase 1** — T003 and T004 read different values into the same record and can be gathered together.

**Phase 4 version pins** — T019, T020, T021 touch three different files with no shared state:

```
T019 .ruby-version
T020 Gemfile:4
T021 Dockerfile:4
```

**Phase 6** — T040, T041, T042 are independent read-only verifications.

## Implementation Strategy

### MVP (recommended first delivery)

**Phase 1 + Phase 2 + Phase 3** — T001 through T012. Declares the last undeclared stdlib dependency, ships on the current runtime, and removes the sole blocker to Ruby 3.4. Roughly two lockfile lines of risk.

### Second increment

**Phase 4** — T013 through T036. The runtime change proper. By this point the blocker is gone and the encryption before-state is captured, so any failure is attributable to the runtime alone.

### Optional

**Phase 5** — the `factory_bot` assessment, deferrable indefinitely.

## Task Summary

| Phase | Story | Tasks | Count |
|-------|-------|-------|-------|
| 1 Setup | — | T001–T004 | 4 |
| 2 Foundational | — | T005–T007 | 3 |
| 3 | US1 (P1) 🎯 | T008–T012 | 5 |
| 4 | US2 (P2) | T013–T036 | 24 |
| 5 | US3 (P3) | T037–T039 | 3 |
| 6 Polish | — | T040–T045 | 6 |
| **Total** | | | **45** |

**Parallel opportunities**: 7 tasks marked `[P]`.

**Independent test criteria**:

- **US1**: lockfile gains only `observer`; suite reproduces the baseline on Ruby 3.3.7.
- **US2**: all source-compiled gems build; suite ≥755 examples with 0 failures; 8 namespaces equivalent; pre-change encrypted data decrypts; container image builds; schema untouched.
- **US3**: a recorded upgrade-or-defer decision exists, and any deferral explains what would retire the workaround.

**Scope note**: this feature changes **no application code**. Expected diff is four files (`Gemfile`, `Gemfile.lock`, `.ruby-version`, `Dockerfile`) plus one new spec. Anything beyond that warrants investigation.
