---

description: "Task list for the Rails 7.2 → 8.0 upgrade"
---

# Tasks: Rails 7.2 → 8.0 Upgrade

**Input**: Design documents from `/specs/009-rails-80-upgrade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/namespace-equivalence.md, quickstart.md

**Tests**: **No new specs are authored.** This feature writes no application behaviour, so the
RED-GREEN cycle does not apply in its usual form — the existing 98-file suite is used as-is, and it
*is* the equivalence evidence (FR-009). T034 re-runs the structural guard spec 007 added
(`spec/requests/fv1/kit_assignment_rollback_spec.rb`) to confirm it survived the framework change.

The governing discipline is therefore not "write tests first" but **"do not weaken the tests that
exist"**: any assertion modified to make a spec pass after the upgrade converts a *detected* contract
change into a *silent* one (T028, T045 — `git diff spec/` must be empty).

**Organization**: Tasks are grouped by user story. US1 is independently shippable on Rails 7.2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Exact file paths included in every task

## Path Conventions

Rails 7 API-only application at repository root. This is an upgrade: the files that change are
dependency manifests (`Gemfile`, `Gemfile.lock`) and framework configuration (`config/`). Files
under `app/` and `db/` are **verified unchanged**, not edited.

---

## Phase 1: Setup (Baseline Capture)

**Purpose**: Establish the measured pre-upgrade state. Every "unchanged" claim in this feature is
asserted against what is recorded here.

- [X] T001 Confirm runtime is Ruby 3.4.10 and framework is Rails 7.2.3 via `ruby -v` and `grep "rails (" Gemfile.lock`; abort if either differs (plan.md Technical Context, invariant I5)
- [X] T002 Run `bundle exec rspec` and record example count, failure count, and runtime into `specs/009-rails-80-upgrade/baseline.md` (FR-021, SC-004)
- [X] T003 [P] Snapshot `Gemfile.lock` to `/tmp/baseline-009-Gemfile.lock` as the comparison basis for lockfile drift (FR-004, SC-003)
- [X] T004 [P] Snapshot `db/schema.rb` to `/tmp/baseline-009-schema.rb` and record its `define_version` value in `baseline.md` (FR-020, SC-014)
- [X] T005 [P] Record the current commit SHA in `baseline.md` as the revert target (FR-025, SC-016)
- [X] T005a [P] Snapshot the route inventory to `/tmp/baseline-009-routes.txt` via `bin/rails routes`, and record the route count in `baseline.md` — this is the "before" side of the reachability comparison in T029a, without which that check has nothing to compare against (FR-010, SC-006)
- [X] T005b Persist an encryption probe **on Rails 7.2.3**, before any dependency changes: set and save an `ApiAccount#settings` value (e.g. `{ probe: "pre-rails-80" }`), and record the record's identifier in `baseline.md`. T031 decrypts this exact record after the upgrade — written after the change it would only prove same-version behaviour, not cross-version compatibility (FR-015, SC-010)

**Gate**: suite green with 0 failures. **If not, stop** — every later comparison is meaningless
against a red baseline. The encryption probe (T005b) must exist and be recorded before Phase 2
begins; it cannot be created retroactively.

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: Prove which gems actually block Rails 8.0, rather than trusting the planning scan.
Nothing else can proceed until this is known.

- [X] T006 Temporarily set `gem "rails", "~> 8.0.5"` in `Gemfile`, run `bundle lock`, capture the resolution failure output into `specs/009-rails-80-upgrade/baseline.md`, then immediately `git checkout Gemfile` (FR-001)
- [X] T007 Confirm the captured failure names exactly `rails-i18n` and `annotate`; record any third blocker in `baseline.md` and treat it as an equal-priority blocker before continuing (FR-001, spec.md Edge Cases)

**Gate**: the blocker set is proven by resolution and recorded. A scan finds gems that *say* they are
incompatible; only resolution is authoritative.

**⚠️ Blocks all user stories** — US1 cannot start without T007.

---

## Phase 3: User Story 1 — Unblock the dependency graph (Priority: P1)

**Goal**: Clear the blocking dependency that *can* be cleared independently — the annotation gem —
while holding every unrelated gem still.

**Independent Test**: `annotate` is gone, `annotaterb` resolves, and the suite reproduces the
baseline — all on Rails 7.2.3, verifiable without changing any application code.

**Ships independently**: yes. Removing a gem that Bundler would otherwise silently downgrade to a
2014 release is worth shipping whether or not the framework bump proceeds.

**Scope reduced during implementation**: the locale gem moved to Phase 4 (see the note below). It is
not independently clearable.

### Blocker 1 — the locale gem → **MOVED TO PHASE 4**

> **Sequencing corrected during implementation.** `rails-i18n` 8.x declares
> `railties (>= 8.0.0, < 9)`, so it **cannot** be installed while Rails is 7.2.3 — resolution fails
> with *"rails-i18n >= 8.0.0 is incompatible with rails >= 7.2.3"*. The planning assumption that both
> blockers could be cleared before the bump was wrong for this one: `rails-i18n` and `rails` are an
> **atomic pair**. T008–T010 are renumbered T017a–T017c and execute in Phase 4 alongside the Rails
> bump. See `baseline.md` → "Why `rails-i18n` did not block".

### Blocker 2 — the annotation gem

- [X] T011 [US1] Replace `gem 'annotate'` with `gem "annotaterb"` in the `:development, :test` group of `Gemfile`, adding a comment recording that `annotate` 3.2.0 is its final release and caps `activerecord < 8.0` (FR-003, research.md R3)
- [X] T012 [US1] Run `bundle lock` and verify via `git diff Gemfile.lock` that `annotate` was removed, `annotaterb` added, and nothing else moved (FR-003, FR-004)
- [X] T013 [US1] Generate annotations into a scratch state, inspect `git diff --stat` against the 39 currently-annotated models, and record the decision in `specs/009-rails-80-upgrade/annotation-assessment.md`: commit the regeneration only if blocks are semantically equivalent, otherwise `git checkout app/models/` and defer (FR-003, SC-002, research.md R3)

### Verification and delivery

- [X] T014 [US1] Run `bundle exec rspec` and confirm it reproduces the T002 baseline exactly — same example count, zero failures (FR-021, FR-022)
- [X] T015 [US1] Commit Phase 1 blockers as a standalone change that ships on Rails 7.2.3 independently of the framework bump

**Checkpoint**: the annotation blocker is cleared, suite reproduces baseline, still on Rails 7.2.3.
The locale blocker is deferred to Phase 4 by necessity, not choice.

---

## Phase 4: User Story 2 — Preserve every published API contract (Priority: P1)

**Goal**: Raise the framework to Rails 8.0.5.x with all 11 namespaces returning byte-identical
responses.

**Independent Test**: Every namespace's request specs pass after the bump with **zero assertions
modified** — `git diff spec/` must be empty.

**Depends on**: US1 (resolution must succeed before the framework can be bumped).

### The bump

- [X] T016 [US2] Confirm the latest available 8.0.x patch via `gem list -r -e rails --all`; planning assumed 8.0.5.1 — if a newer 8.0.x has published, take it and record the difference and reason in `baseline.md`. Do **not** take 8.1 (FR-005, research.md R1)
- [X] T017 [US2] Set `gem "rails", "~> 8.0.5"` in `Gemfile` (FR-005)
- [X] T017a [US2] Pin `gem "rails-i18n", "~> 8.0"` in `Gemfile` **in the same edit as T017** — `rails-i18n` 8.x requires `railties >= 8.0.0`, so the two are an atomic pair and neither resolves without the other (FR-002, baseline.md)
- [X] T017b [US2] Run `bundle lock --conservative --update rails rails-i18n` — both gems named together, since updating either alone fails resolution (FR-002, FR-005, FR-004)
- [X] T017c [US2] Verify both locales resolve after the pair moves: run the `I18n.t` probe from quickstart.md across `errors.messages.{blank,taken,invalid,required}`, `number.format.separator` and `date.formats.default`; confirm zero `__MISSING__` results and that Polish strings are Polish (FR-002, SC-012)
- [X] T018 [US2] Inspect `git diff Gemfile.lock` and confirm only framework gems and gems Rails itself forces have moved; stop and investigate if `rspec-rails`, `sentry-*`, `alba`, `oj` or any other unrelated gem shifted (FR-004, SC-003)
- [X] T019 [US2] Run `bundle install` and verify `bin/rails runner 'puts Rails.version'` reports the target 8.0.5.x version; confirm resolution completed with zero conflicts and that the resolved version matches the latest 8.0.x confirmed in T016 (FR-005, FR-007, SC-001)

### Configuration review

- [X] T020 [US2] Run `bin/rails app:update` and review **every** proposed hunk individually via `git diff`, applying or rejecting each with a recorded reason in `specs/009-rails-80-upgrade/app-update-review.md`; bulk acceptance is forbidden (FR-006)
- [X] T021 [US2] Verify `config/application.rb` retained its deliberate settings after `app:update`: `api_only`, `autoload_lib`, `solid_queue.use_skip_locked`, `active_record.default_column_serializer`, `mission_control.jobs.*`, and the `i18n` locale configuration (FR-006, FR-007)
- [X] T022 [US2] Verify `config/environments/{development,test,staging,production}.rb` retained their deliberate settings after `app:update` (FR-006, FR-007)
- [X] T023 [US2] Confirm `config/initializers/new_framework_defaults_8_0.rb` was created and that **every line remains commented out** — defaults are adopted in US4, not here (FR-018, plan.md Phase Sequencing)

### Contract verification

- [X] T024 [US2] Verify the application boots in development and test configurations via `bin/rails runner` and `RAILS_ENV=test bin/rails runner` (FR-007, SC-013)
- [X] T025 [US2] Run `bundle exec rspec` and confirm zero failures with no reduction in example count against the T002 baseline (FR-022, SC-004)
- [X] T026 [US2] Confirm `git diff db/schema.rb` is empty — a framework upgrade must not alter the schema (FR-020, SC-014, invariant I1)
- [X] T027 [US2] Run the 10 per-namespace spec commands from `contracts/namespace-equivalence.md` and record pass/fail per namespace in `specs/009-rails-80-upgrade/equivalence-report.md` (FR-009, SC-005)
- [X] T028 [US2] Confirm `git diff spec/` is empty — **any assertion modified to make a spec pass is a contract change, not a test fix**; escalate and explain the underlying behavioural difference before touching any spec (FR-009, SC-005, invariant I3)
- [X] T029 [US2] Verify `patient_portal` structurally: routes load and the namespace is mounted, and confirm it is not reachable without authentication (FR-010, contracts/namespace-equivalence.md)
- [X] T029a [US2] Verify authentication outcomes across all 11 namespaces: valid credentials admitted and invalid refused, confirmed by the auth-related examples in the per-namespace runs; and confirm no endpoint became newly reachable by diffing `bin/rails routes` against the **T005a** snapshot at `/tmp/baseline-009-routes.txt`, which must show no added routes (FR-010, SC-006, invariant I8)
- [X] T029b [US2] Verify validation-failure responses are unchanged in structure, status code, and field naming by confirming the error-path examples in `spec/requests/` pass with unmodified assertions across the 11 namespaces (FR-011, SC-007)
- [X] T029c [US2] Verify parameter handling still rejects the same malformed and missing-parameter requests with the same status codes, and confirm the 25 `params.require` sites are unmodified via `git diff app/controllers/` — the newer `params.expect` style is explicitly out of scope (FR-012, SC-007)
- [X] T030 [US2] Record in `equivalence-report.md` the coverage assessment per namespace, explicitly naming the thin-coverage namespaces — `lalen` (2 files, partner-facing), `masdiag_mailer` (1), `webhook` (1), `diagnostyka_precyzyjna` (1), `patient_portal` (0) — and stating that the equivalence claim is correspondingly weaker there (FR-009a, SC-005)

**Checkpoint**: Rails 8.0.5.x installed, suite green, all 11 namespaces verified, schema untouched,
zero assertions modified.

---

## Phase 5: User Story 3 — Keep partner-facing side effects correct (Priority: P1)

**Goal**: Confirm the two-layer partner-notification protection from spec 007 survived, and verify
encryption, jobs, the dashboard, and the container.

**Independent Test**: A committed kit assignment produces exactly one partner notification; a
rolled-back one produces none — observed against a real worker.

**Depends on**: US2 (the framework must be bumped and the suite green before behaviour is judged).

### Encryption

- [X] T031 [US3] Verify field-level encryption round-trips across the upgrade by loading the probe record created in **T005b** (identifier recorded in `baseline.md`), confirming its `settings` value decrypts to what was written on Rails 7.2.3 and that the ciphertext contains no plaintext (FR-015, SC-010)

### Partner notification — the irreversible one

- [X] T032 [US3] Start a real worker with `bin/rails solid_queue:start` — the test adapter cannot prove this, since `use_transactional_fixtures` makes the controller transaction a savepoint (FR-013, research.md R6)
- [X] T033 [US3] Exercise the FFTB kit-assignment flow through `app/controllers/fv1/kit_controller.rb` twice — once committing, once forcing a rollback — and confirm exactly 1 partner notification on commit and 0 on rollback (FR-013, SC-008)
- [X] T034 [US3] Confirm `spec/requests/fv1/kit_assignment_rollback_spec.rb` still passes with unmodified assertions, verifying the spec 007 structural guard survived the framework change (FR-013, FR-009)
- [X] T035 [US3] Verify background jobs are enqueued, picked up, and retried as before under the real worker; confirm all 48 jobs in `app/jobs/` still declare `wait: :polynomially_longer` or an explicit duration (FR-016, constitution Development Workflow item 4)

### The dashboard — the least obvious risk

- [X] T036 [US3] Start the server and open `http://localhost:3000/jobs` **in a browser**, confirming the page renders with styling applied and scripts loaded, and that the network tab shows zero failed asset requests — HTTP 200 alone is insufficient, since a broken stylesheet still returns 200 (FR-008a, SC-013b, research.md R5)
- [X] T037 [US3] Verify `AdminController` authentication still admits valid credentials, refuses invalid ones, and that `/jobs` is never reachable unauthenticated (FR-008b, SC-013b)

### Container

- [X] T038 [US3] Run `docker compose build` and confirm the image builds against `ruby:3.4.10-slim`, whose toolchain differs from the workstation's (FR-008, SC-013)
- [X] T039 [US3] Run `docker compose run --rm app bin/rails runner 'puts Rails.version'` and confirm the application boots inside the container; if it fails with `Expected name: to be a String, got NilClass` at `admin_controller.rb`, that is the known `RAILS_MASTER_KEY`-at-runtime gap in `docker-compose.yml`, not an upgrade regression (FR-008, SC-013)

**Checkpoint**: partner guarantee verified, encryption intact, dashboard renders, container boots.

---

## Phase 6: User Story 4 — Adopt the new framework defaults (Priority: P2)

**Goal**: Finish with `load_defaults 8.0` active and the partner-notification guarantee set
explicitly rather than inherited.

**Independent Test**: The suite and all 11 namespaces pass a **second** time, after adoption.

**Depends on**: US2 and US3. The separation is what makes a defaults-induced failure distinguishable
from a bump-induced one.

### Adoption

- [X] T040 [US4] Change `config.load_defaults 7.2` to `config.load_defaults 8.0` in `config/application.rb` (FR-018, SC-013a)
- [X] T041 [US4] Add an explicit `config.active_job.enqueue_after_transaction_commit` setting to `config/application.rb` with a comment citing constitution Development Workflow item 4 — ordering-critical enqueue intent must survive a defaults change, and this upgrade is that change (FR-014, SC-009, research.md R6)
- [X] T042 [US4] Review `config/initializers/new_framework_defaults_8_0.rb` line by line, recording each default's decision and reason in `specs/009-rails-80-upgrade/defaults-decisions.md` (FR-006, FR-019, SC-015)

### Re-verification

- [X] T043 [US4] Run `bundle exec rspec` and confirm the same results as before adoption — zero failures, no example-count reduction (FR-018, SC-004, SC-013a)
- [X] T044 [US4] Re-run all 10 per-namespace spec commands from `contracts/namespace-equivalence.md` and append the second-pass results to `equivalence-report.md` (FR-009, SC-013a)
- [X] T045 [US4] Confirm `git diff spec/` is still empty after adoption (FR-009, invariant I3)
- [X] T046 [US4] Verify the enqueue setting now reads from explicit configuration rather than an inherited default via `bin/rails runner 'puts ActiveJob::Base.enqueue_after_transaction_commit.inspect'` (FR-014, SC-009)
- [X] T047 [US4] Repeat the commit/rollback exercise from T033 under the adopted defaults, confirming 1 notification on commit and 0 on rollback — this is what proves the guarantee survived the defaults change (FR-013, FR-014, SC-008)

### Regex timeout

- [X] T048 [US4] Verify `LalenApi::RegisterKit::EMAIL_REGEXP` in `app/models/lalen_api/register_kit.rb` reaches identical verdicts under the new `Regexp.timeout` for valid, invalid, empty, and unusually long inputs, with zero `Regexp::TimeoutError` — this is the one regex applied to partner-supplied input (FR-017, SC-011, research.md R7)
- [X] T049 [US4] [P] Verify the remaining 5 regex sites, including `app/services/masdiag/reserved_sample_codes_creator.rb:43`, reach identical verdicts with zero timeouts (FR-017, SC-011)
- [X] T050 [US4] Confirm `git diff db/schema.rb` is still empty after adopting the 8.0 defaults, which change schema-dump column ordering; do **not** run `db:schema:dump` (FR-020, SC-014, research.md R8)

**Checkpoint**: 8.0 defaults active, everything verified a second time, regex sites clear.

---

## Phase 7: User Story 5 — Leave a record the next upgrade can use (Priority: P3)

**Goal**: A developer who did not perform the upgrade can revert it, or continue to a later version,
from the record alone.

**Independent Test**: Someone else follows the revert procedure and reproduces the baseline exactly.

**Depends on**: US1–US4 (there is nothing to record until the work is done).

- [X] T051 [US5] Run `bundle exec rspec 2>&1 | grep -iE "warning|deprecat" | sort -u` and record each warning as resolved or deliberately accepted with a rationale in `specs/009-rails-80-upgrade/deprecations.md` (FR-023, SC-015)
- [X] T052 [US5] Finalise `specs/009-rails-80-upgrade/equivalence-report.md` with both verification passes and the per-namespace coverage assessment (FR-009a, SC-005)
- [X] T053 [US5] Write `specs/009-rails-80-upgrade/upgrade-record.md` covering: framework version before and after, every dependency that moved and why, every default adopted and why, the annotation-regeneration decision, and every deferred item with its reason (FR-024, SC-017)
- [X] T054 [US5] Document the revert procedure in `upgrade-record.md`, specifying that `Gemfile`, `Gemfile.lock`, `config/application.rb` and `config/initializers/new_framework_defaults_8_0.rb` revert **together** — spec 007 reverted only the lockfile, left newer code in place, and produced 13 failures that masked the real state (FR-025, SC-016)
- [X] T055 [US5] Verify the documented revert procedure actually reproduces the T002 baseline, then restore the upgraded state (FR-025, SC-016)

**Checkpoint**: the upgrade is documented, reversible, and verified reversible.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T056 [P] Correct the namespace table in `CLAUDE.md`, which lists nine namespaces and omits `toxo` and `diagnostyka_precyzyjna`; `config/routes.rb` declares eleven and is authoritative (research.md R9)
- [X] T057 [P] Record in `upgrade-record.md` that Rails 8.1 is available (8.1.3.1) and is a candidate for a future spec 010, deliberately excluded here to avoid conflating two sets of breaking changes (research.md R1, R10)
- [X] T058 [P] Record in `upgrade-record.md` that the `factory_bot` 4.11 → 6.x upgrade remains deferred and is still the change that would retire the `observer` declaration in `Gemfile` (research.md R10)
- [X] T059 Run the full completion checklist in `quickstart.md` and confirm every item is satisfied

---

## Dependencies & Execution Order

### Phase dependencies

```
Phase 1 (Setup)          →  baseline recorded; blocks everything
Phase 2 (Foundational)   →  blocker set proven; BLOCKS all user stories
Phase 3 (US1, P1)        →  blockers cleared; SHIPS INDEPENDENTLY on Rails 7.2.3
Phase 4 (US2, P1)        →  requires US1 (resolution must succeed to bump)
Phase 5 (US3, P1)        →  requires US2 (suite must be green before judging behaviour)
Phase 6 (US4, P2)        →  requires US2 + US3 (separation localises failures)
Phase 7 (US5, P3)        →  requires US1–US4 (nothing to record until done)
Phase 8 (Polish)         →  T056–T058 can run any time; T059 last
```

### Story independence

| Story | Independently shippable? | Notes |
|---|---|---|
| US1 | **Yes** | Clearing blockers is valuable on Rails 7.2.3 whether or not the bump proceeds |
| US2 | No | Requires US1 |
| US3 | No | Verifies US2's result |
| US4 | No | Deliberately sequenced after US2/US3 so failures are attributable |
| US5 | No | Documents the completed work |

### Parallel opportunities

Genuinely limited — this is a sequential upgrade where most steps gate the next.

- **Phase 1**: T003, T004, T005, T005a (independent snapshots). **T005b is not parallel** — it writes a database record and must complete before Phase 2, since the probe cannot be created retroactively
- **Phase 4**: T021 and T022 (different config files) after T020
- **Phase 6**: T049 alongside T048 (different regex sites)
- **Phase 8**: T056, T057, T058 (different documentation concerns)

Everything else is strictly ordered. Attempting to parallelise the bump or the verification defeats
the sequencing that makes failures attributable.

---

## Implementation Strategy

### MVP

**Phase 1 + Phase 2 + Phase 3 (US1)** — clear both blockers on Rails 7.2.3 and commit. This is a
complete, useful increment: it removes a dead gem, moves the locale gem onto a maintained line, and
proves Rails 8 can resolve. If the upgrade is abandoned after this point, the codebase is strictly
better off.

### Incremental delivery

1. **US1** → commit; ships on Rails 7.2.3
2. **US2** → framework bumped, contracts verified; the point of no easy return
3. **US3** → behaviour verified; the partner guarantee confirmed
4. **US4** → defaults adopted; everything verified a second time
5. **US5** → recorded and proven reversible

### Where this goes wrong

The three failure modes worth naming, drawn from the risk register:

1. **An assertion gets relaxed to make a spec pass** (T028, T045). This converts a *detected*
   contract change into a *silent* one. It is tempting under time pressure and undetectable
   afterwards. `git diff spec/` must be empty.
2. **The dashboard is checked for reachability rather than rendering** (T036). A broken stylesheet
   returns HTTP 200. The check must be a real render in a browser.
3. **`db:schema:dump` gets run** (T026, T050). Rails 8.0 reorders columns, making the diff look
   legitimate — and in spec 007 a dump from a stale database silently deleted two table definitions.

---

## Task Summary

| Phase | Story | Tasks | Count |
|---|---|---|---|
| 1 — Setup | — | T001–T005b | 7 |
| 2 — Foundational | — | T006–T007 | 2 |
| 3 — Unblock dependencies | US1 (P1) | T008–T015 | 8 |
| 4 — Preserve API contracts | US2 (P1) | T016–T030 (incl. T029a–c) | 18 |
| 5 — Partner side effects | US3 (P1) | T031–T039 | 9 |
| 6 — Adopt defaults | US4 (P2) | T040–T050 | 11 |
| 7 — Upgrade record | US5 (P3) | T051–T055 | 5 |
| 8 — Polish | — | T056–T059 | 4 |
| **Total** | | | **64** |

**Requirement coverage**: verified mechanically — all 28 functional requirements (FR-001 – FR-025,
including FR-008a, FR-008b, FR-009a) and all 19 success criteria are cited by at least one task,
with zero uncited.

T029a–T029c were added after a coverage check found FR-010's auth-outcome assertion, FR-011
(validation error shapes) and FR-012 (parameter rejection) had no task actually verifying them —
they were implied by "run the namespace specs" but never checked as distinct properties. SC-001 was
likewise folded into T019.

T005a and T005b were added after `/speckit-analyze` found two verification steps with no "before"
side to compare against. T031 required decrypting data "persisted before the framework change" while
sitting in Phase 5, with no task ever creating that record — unperformable as written. T029a
compared route counts "against the baseline" while Phase 1 captured no routes. Both gaps were
ordering failures rather than missing citations: the checks were cited correctly and still could not
have been carried out.
