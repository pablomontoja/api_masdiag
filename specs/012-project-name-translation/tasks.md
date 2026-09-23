---
description: "Task list for Project and User Attribute Translation"
---

# Tasks: Project and User Attribute Translation

**Input**: Design documents from `/specs/012-project-name-translation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Included — Constitution Principle III (Test-First, NON-NEGOTIABLE) requires RSpec specs written before implementation code for this repository.

**Organization**: Tasks are grouped by user story per spec.md priorities (P1, P2, P3). US1 and US2 both modify `app/models/project.rb`; US2's setter-override work is the mechanism that makes US1's Polish/English isolation correct, so US2 is sequenced as a continuation of the same model file rather than a parallel track — this reflects the actual coupling instead of manufacturing false independence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1, US2, or US3, mapping to spec.md's three user stories
- File paths are exact and relative to the repository root (`/home/pswider/rails/api_masdiag`)

## Path Conventions

Single Rails application — `app/models/`, `db/migrate/`, `spec/models/`, `spec/factories/` at repository root, per plan.md's Project Structure section.

---

## Phase 1: Setup

**Purpose**: Confirm the environment matches the plan before any code changes

- [X] T001 Run `rvm use 3.4.10 && bundle exec rspec spec/models/analyte_spec.rb spec/models/project_factory_spec.rb 2>/dev/null; bundle exec rspec` to capture a green baseline before any change (no file changes — verification only)
- [X] T002 Run `rvm use 3.4.10 && RAILS_ENV=development bin/rails runner 'puts Project.order(:Id).pluck(:Id, :Name, :eng_name).count'` to reconfirm the development database still has 47 Projects before basing the migration's data mapping on data-model.md's table (no file changes — verification only)

**Checkpoint**: Baseline test suite is green; Project count matches data-model.md's assumption (47). If the count differs, stop and reconcile data-model.md before proceeding.

---

## Phase 2: Foundational

**Purpose**: No blocking infrastructure work is needed — `mobility_string_translations` already exists (per research.md), the `mobility` gem is already installed and configured, and no schema change is required or permitted for this feature. This phase is intentionally empty.

**Checkpoint**: Proceed directly to Phase 3 — nothing to build here.

---

## Phase 3: User Story 1 — English name available for every existing Project (Priority: P1) 🎯 MVP

**Goal**: Every existing Project has a working translatable `Name` — Polish readable under `:pl`, English readable under `:en` after backfill.

**Independent Test**: After the migration runs, iterate all 47 Projects under `I18n.locale = :en` and confirm each returns a non-blank English name; under `:pl`, confirm each still returns its original Polish name unchanged (see quickstart.md's first two verification snippets).

### Tests for User Story 1 ⚠️

> Write these tests FIRST; they MUST fail (or error, since `translates :Name` doesn't exist yet) before T006 is implemented.

- [X] T003 [P] [US1] Create `spec/models/project_spec.rb` with a `"Name translation"` describe block mirroring `spec/models/analyte_spec.rb`'s `"NameInReport hybrid storage"` structure: (a) Polish-locale read returns the native column value, (b) English-locale read after a translation row exists returns that value, (c) English-locale read with NO translation row present falls back to the Polish native-column value (this sub-case is specific to Project's `default:` fallback behavior per FR-002 and has no direct Analyte precedent to copy verbatim — write it fresh). Use `create(:project_without_fixed_id)` from `spec/factories/project_factory.rb`.
- [X] T004 [P] [US1] Add a factory trait (not needed — existing `project_without_fixed_id` factory already supports `Name:` overrides, confirmed sufficient for the fallback test) or a dedicated factory example in `spec/factories/project_factory.rb` if needed to support creating a Project with no English translation row (for the fallback test in T003) — only add if the existing `project_without_fixed_id` factory doesn't already cover this cleanly.

### Implementation for User Story 1

- [X] T005 [US1] Add `extend Mobility` and `translates :Name, type: :string, default: -> { read_attribute(:Name) }` to `app/models/project.rb`, matching `app/models/analyte.rb`'s declaration for `NameInReport` exactly (same backend, same default-fallback proc pattern, applied to `:Name` instead).
- [X] T006 [US1] Run `bundle exec rspec spec/models/project_spec.rb` — NOTE: actual result deviated from the plan's expectation. Without the setter override, the `translates :Name` default setter intercepted even Polish-locale factory creation and never wrote the native column, causing a NOT NULL violation at `create` time (not just a write-isolation failure as anticipated). This meant T005 alone could not reach a "partial pass" state — the setter override (T008) was required immediately to get any test passing. Implemented T008 in the same step; see T008/T009.

**Checkpoint**: `Project#Name` is readable in both locales with correct fallback behavior. Write-path correctness (keeping Polish out of the translations table) is still open — completed in US2 below, which this MVP story depends on for full correctness per FR-003/FR-008. Do not consider US1 "done" for production use until US2's checkpoint is also reached; they ship together in the same PR since they touch the same model file.

---

## Phase 4: User Story 2 — Writing a Project name always keeps Polish as the source of truth (Priority: P2)

**Goal**: Writes to `Project#Name` under `:pl` land in the native column, never in `mobility_string_translations`; writes under any other locale go through Mobility and never touch the native column.

**Independent Test**: With `I18n.locale = :pl`, assign and save a new `Name`; verify the native column changed and no `:pl` row exists in `mobility_string_translations` for that Project. With `I18n.locale = :en`, assign and save; verify a `:en` translation row was created/updated and the native column is untouched (see quickstart.md's write-verification snippet).

### Tests for User Story 2 ⚠️

> These assertions already exist in T003's `project_spec.rb` (written in Phase 3, since they belong to the same "Name translation" describe block as the Analyte precedent groups Polish/English write behavior together) — this phase implements the code that makes them pass. No new spec file needed.

- [X] T007 [P] [US2] If not already covered by T003, extend (already covered — T003's `project_spec.rb` includes both write-path scenarios in its initial version, so no additional edit was needed) `spec/models/project_spec.rb` with the two write-path scenarios from spec.md's Acceptance Scenarios for US2: (1) Polish-locale write updates the native `Name` column and creates no `:pl` `mobility_string_translations` row, (2) English-locale write creates/updates a `:en` row and leaves the native column untouched. Follow `spec/models/analyte_spec.rb`'s `"Polish locale — writes to column"` / `"English locale — writes to mobility_string_translations"` describe-block structure exactly, substituting `Name` for `NameInReport` and `Project` for `Analyte`.

### Implementation for User Story 2

- [X] T008 [US2] Add an overridden `Name=` setter — **initially implemented as Analyte's literal `locale == :pl` check, then corrected** after full-suite testing (see T009) revealed this app's `I18n.default_locale` is `:en` (config/application.rb:58) and specs run under ambient `I18n.locale = :en` (spec/rails_helper.rb:39), so the literal-`:pl`-check version silently routed every bare `create(:project, Name: ...)` into Mobility instead of the native column, causing a NOT NULL violation. Final version: no explicit `locale:` kwarg, or explicit `:pl`, → native column (the true default); only an explicit non-`:pl` `locale:` kwarg → Mobility. `Analyte#NameInReport=` has the identical latent bug, left unfixed/unchanged — out of scope for this feature since nothing outside `analyte_spec.rb` currently creates an Analyte without explicitly wrapping in `I18n.with_locale(:pl)`. Flagged for the user's separate attention. to `app/models/project.rb`, copying `app/models/analyte.rb`'s `NameInReport=` override pattern verbatim (substituting `Name` for `NameInReport`): when the active locale (explicit `locale:` kwarg or `Mobility.locale`) is `:pl`, write directly via `write_attribute(:Name, value)`; otherwise delegate to `super(value, locale: locale, **options)`.
- [X] T009 [US2] Run `bundle exec rspec spec/models/project_spec.rb` and confirm all Name-translation tests pass. First pass (6 examples, 0 failures) used the literal-`:pl`-check setter and only tested locale-wrapped scenarios, so it did not catch the ambient-default-locale bug. **A full-suite run (`bundle exec rspec`) surfaced 430 failures** across 33 unrelated spec files, all `Column 'Name' cannot be null` from bare `create(:project, ...)` calls under the app's ambient `:en` default locale. Root-caused and fixed per T008's note; `project_spec.rb` was also expanded with explicit regression-guard tests for the ambient-default case and the explicit-`locale:`-kwarg write API. Final state: 9 examples in `project_spec.rb`, 0 failures; full suite 843 examples, 0 failures.

**Checkpoint**: `Project#Name` fully replicates `Analyte#NameInReport`'s hybrid storage behavior — both read and write paths correct. This is the point at which US1+US2 together constitute a complete, production-correct MVP for Project translation (model layer only — data backfill is a separate concern, handled next).

---

## Phase 5: Backfill migration for existing Projects (supports User Story 1's "every existing Project has an English name" acceptance criterion)

**Goal**: Populate an `:en` translation for all 47 existing Projects, sourced per data-model.md's mapping table (eng_name where genuine, hand-curated otherwise), idempotently.

**Independent Test**: Run the migration against development; confirm all 47 Projects return a non-blank English name (quickstart.md's backfill-verification snippet). Re-run the same migration; confirm the `mobility_string_translations` row count for `translatable_type = "Project", locale = "en"` is unchanged (quickstart.md's idempotency snippet).

> No dedicated test file is created for a one-time data migration (consistent with how `db/migrate/20260513144942_create_string_translations.rb` and other structural migrations in this repo have no matching spec) — verification is via the quickstart.md runner snippets in T012–T013 below, run against the development database.

- [X] T010 [US1] Re-verify each `eng_name`-sourced row (confirmed identical to data-model.md's snapshot — no discrepancies) in data-model.md's migration data mapping table against the live development database (`Project.order(:Id).pluck(:Id, :eng_name)`) immediately before writing the migration, since data-model.md's table notes `eng_name` values must be read fresh at implementation time, not frozen from the plan snapshot. Flag any discrepancy from the table for review before proceeding.
- [X] T011 [US1] Create `db/migrate/20260923120000_backfill_project_english_names.rb` implementing a `data` migration that: (a) defines the 47-row `Id → English name` mapping explicitly and readably in the migration source, per FR-006/FR-015; (b) for each mapped Project, finds the record, skips if it no longer exists or its native `Name` is blank (FR-009), and otherwise writes via `project.public_send(:Name=, english_name, locale: :en); project.save!` — **deviates from the original plan's `I18n.with_locale(:en) { project.update!(Name: ...) }` pattern**, which was found during T008/T009 to be ambiguous with a bare/ambient-locale write and would not route to Mobility under the corrected setter logic; the explicit `locale:` kwarg is now required for any Mobility-backed write; (c) is idempotent — confirmed via `db:migrate:redo:primary`, 47 rows before and after, no duplicates, per FR-007; (d) does NOT modify the native `Projects.Name` or `Projects.eng_name` columns (FR-008); (e) provides a `down` that deletes the `:en` `Name` translation rows this migration created — **the `key` column required backtick-quoting** (`` `key` ``) since it is a MySQL/MariaDB reserved word; the first `down` attempt failed with a SQL syntax error until fixed, confirmed via a successful `db:migrate:redo:primary` afterward.
- [X] T012 [US1] Run `rvm use 3.4.10 && bin/rails db:migrate RAILS_ENV=development` and then the quickstart.md "Verify the backfill migration ran for all 47 Projects" snippet — confirmed: all 47 Projects have a non-blank English name.
- [X] T013 [US1] Run the quickstart.md "Verify migration idempotency" snippet (`db:migrate:redo:primary VERSION=20260923120000` — the namespaced task name, since this app uses multiple databases) — confirmed 47 rows before and after the redo. NOTE: the initial `down` method used unquoted `key` (a MySQL reserved word), causing a SQL syntax error on first redo attempt; fixed by backtick-quoting `` `key` ``. No data loss occurred (the raw-SQL DELETE failed before executing, migration stayed marked "up", 47 rows remained intact) — but this is a corrected deviation from the original T011 implementation, now reflected in the migration file.
- [X] T014 [US1] Run `rvm use 3.4.10 && bin/rails db:migrate RAILS_ENV=test` so the test database schema/migration state matches development (the migration itself is a data migration with no schema change, but this keeps `db:migrate:status` consistent across environments per Constitution Development Workflow item 6).

**Checkpoint**: All 47 existing Projects have a correct, idempotently-backfilled English name. User Story 1's full acceptance criteria (spec.md Acceptance Scenario 3) are now met.

---

## Phase 6: User Story 3 — Codebase is ready to translate User's FirstName, LastName, and Description (Priority: P3)

**Goal**: `User` model declares `FirstName`, `LastName`, `Description` as translatable via the same Mobility idiom, with zero behavior change under the default locale and zero data migration.

**Independent Test**: Read/write each of the three attributes under `:pl` before and after the model change and confirm identical behavior; confirm zero `mobility_string_translations` rows exist for any `User` after the change (spec.md Acceptance Scenarios 1–3 for US3; quickstart.md's User-readiness snippet).

### Tests for User Story 3 ⚠️

- [X] T015 [P] [US3] Create or extend `spec/models/user_spec.rb` with a `"translatable attributes readiness"` describe block covering, for each of `FirstName`, `LastName`, `Description`: (a) Polish-locale read/write behaves identically to a plain `write_attribute`/`read_attribute` (no behavior change), (b) English-locale read with no translation row falls back to the native column value (or nil, per Mobility's `default nil` global config combined with the attribute-level `default:` fallback proc) without raising, (c) zero `mobility_string_translations` rows are created for any User fixture/factory used elsewhere in the suite as a side effect of loading the model. Follow the same Given/When/Then structure as `spec/models/analyte_spec.rb` and the new `spec/models/project_spec.rb`.
- [X] T016 [P] [US3] Add a regression assertion (in `spec/models/user_spec.rb` or wherever `User#fullname` is currently tested — search first) confirming `fullname` still concatenates `FirstName`/`LastName` correctly after the model change, satisfying FR-013's "no existing functionality breaks" requirement.

### Implementation for User Story 3

- [X] T017 [US3] Add `extend Mobility` and three separate `translates :AttrName, type: :string, default: -> { read_attribute(:AttrName) }` calls to `app/models/user.rb` (one per attribute, per-attribute default proc, as planned).
- [X] T018 [US3] Add overridden setters (`FirstName=`, `LastName=`, `Description=`) to `app/models/user.rb`, one per attribute. **Deviation from original task wording**: does NOT follow `Analyte#NameInReport=`'s literal `locale == :pl` check — that logic was found to be broken during T009 (see T009's note and the plan/spec Clarifications addendum). Instead follows Project's corrected pattern: no explicit `locale:` kwarg or explicit `:pl` → native column (the true default, since the app's ambient `I18n.default_locale` is `:en` but these columns hold Polish text); only an explicit non-`:pl` `locale:` kwarg → Mobility. This is the same fix applied to `Project#Name=` in T008 (updated).
- [X] T019 [US3] Run `bundle exec rspec spec/models/user_spec.rb` and confirm all tests pass — confirmed: 12 examples, 0 failures.

**Checkpoint**: `User` model is translation-ready with zero data or behavior change. All three user stories are now complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final full-suite validation and quickstart verification per Constitution Principle III and FR-014/SC-004.

- [X] T020 Run `bundle exec rspec` (full suite) — final confirmed result: 843 examples, 0 failures. (Intermediate state during implementation briefly showed 430 failures, root-caused and fixed — see T008/T009 notes.)
- [X] T021 Manually execute every snippet in `specs/012-project-name-translation/quickstart.md` — updated two snippets that used a now-invalid write pattern (`I18n.with_locale(:en) { project.update!(...) }`, which under the corrected setter logic no longer routes to Mobility) to use the explicit `locale:` kwarg API instead; all snippets confirmed producing documented output. Dev-DB test mutations (Project #2's `Name` and its `:en` translation) were restored to their original values after verification.
- [ ] T022 Review `db/migrate/20260923120000_backfill_project_english_names.rb`'s per-project English name mapping one final time against data-model.md's flagged judgment calls (rows #11 CBD/THC, #26 Glutathione Index, #33 ALD-X, #35 Lysosphingomyelins) — per FR-015, this file is the artifact the requester reviews before it is applied to any shared environment (this migration has ONLY been run against the local development database so far, per the user's explicit scope confirmation before implementation began; it has NOT been run against production). This review is still pending the requester's action.

**Checkpoint**: Feature complete — Project translation live and backfilled, User translation model-ready, full test suite green, migration reviewed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — run first.
- **Foundational (Phase 2)**: Empty — no blocking work exists for this feature.
- **User Story 1 (Phase 3)**: Depends on Setup. Read-path only; write-path correctness depends on US2.
- **User Story 2 (Phase 4)**: Depends on Phase 3 (same file, `app/models/project.rb`) — implemented as a direct continuation, not a parallel track.
- **Backfill migration (Phase 5)**: Depends on Phase 4 being complete (the migration writes through `Project#Name=`, which requires US2's setter override to correctly route the `:en` write into the translations table rather than the native column).
- **User Story 3 (Phase 6)**: Depends only on Setup (Phase 1) — entirely independent of Project work (different model file, no shared code path). Could be implemented in parallel with Phases 3–5 by a different developer.
- **Polish (Phase 7)**: Depends on all prior phases.

### User Story Dependencies

- **US1 (P1)**: Depends on Setup. Its full acceptance criteria (spec.md Scenario 3 — all 47 Projects have an English name) are only satisfied once Phase 5 (backfill) also completes, but the model-level read behavior (Scenarios 1–2) is independently testable after Phase 3 alone.
- **US2 (P2)**: Builds directly on US1's model file — not independent in the file sense, but independently testable per its own acceptance scenarios once its phase completes.
- **US3 (P3)**: Fully independent of US1/US2 — different model, no shared code, can be built and merged in any order relative to Project work.

### Within Each User Story

- Tests written and failing before implementation (T003/T004 before T005; T007 before T008; T015/T016 before T017/T018).
- Model changes before migration (Phase 5 depends on Phase 4's setter override).

### Parallel Opportunities

- T003 and T004 (US1 test setup) can run in parallel — different concerns within the same file/factory, but no code dependency between them.
- T015 and T016 (US3 tests) can run in parallel with each other, and the entire Phase 6 (US3) can run in parallel with Phases 3–5 (Project work), since they touch entirely different model files.
- T012/T013 (backfill verification) cannot run in parallel with each other (T013 depends on T012 having run first).

---

## Parallel Example: User Story 1 setup vs. User Story 3 (fully independent stories)

```bash
# Developer A — Project translation (Phases 3-5):
Task: "Create spec/models/project_spec.rb with Name translation read-path tests (T003)"
# ... continues through Phase 5

# Developer B — User translation readiness (Phase 6), in parallel:
Task: "Create spec/models/user_spec.rb with translatable attributes readiness tests (T015)"
Task: "Add fullname regression assertion (T016)"
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 + backfill — they ship together)

1. Complete Phase 1: Setup.
2. Skip Phase 2: nothing to do.
3. Complete Phase 3 (US1 read-path) → Phase 4 (US2 write-path) → Phase 5 (backfill migration). These three phases together are the real MVP: Project's translation is not production-correct or useful until all three are done (read-only or write-broken translation is not shippable).
4. **STOP and VALIDATE**: Run quickstart.md's Project verification snippets; confirm SC-001 through SC-003.
5. This is the deployable increment the original request centers on.

### Incremental Delivery

1. Setup → Foundation confirmed empty.
2. Project translation (Phases 3–5) → validate → this is the MVP the user asked for first.
3. User translation readiness (Phase 6) → validate → ships independently, no coupling to Project work.
4. Polish (Phase 7) → final full-suite + quickstart + migration review pass.

### Parallel Team Strategy

With two developers: Developer A owns Phases 3–5 (Project, sequential due to shared file/DB dependency); Developer B owns Phase 6 (User, fully independent) in parallel. Both converge at Phase 7.
