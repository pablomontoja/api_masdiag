# Feature Specification: Project and User Attribute Translation

**Feature Branch**: `012-project-name-translation`

**Created**: 2026-09-23

**Status**: Draft

**Input**: User description: "model Analyte używa gemu Mobility do translacji NameInReport na język angielski, ale robi to w szczególny sposób - otóż nazwy polskie przechowywane są w tabeli Analyte a nazwy angielskie zgodnie z konwencją Mobility czyli w mobility_string_translations ; przygotuj analogicznie model Project do translacji atrybutu Name; przygotuj migrację, która zrobi wpisy angielskich Project.Name używając I18n.locale = :en i przygotowanych przez Ciebie angielskich nazw w oparciu o obecną bazę development gdzie jest 47 Projects tak samo jak w bazie produkcyjnej; ponadto przygotuj się do translacji modelu User i atrybutów FirstName, LastName oraz Description - na razie bez migracji"

## Clarifications

### Session 2026-09-23

- Q: Should the existing `Projects.eng_name` column be reused as a source for the migration's curated English names, or treated as unrelated legacy data? → A: Use `eng_name` as the migration's data source where its value is genuinely an English name (not blank, not Polish, not otherwise unreliable); hand-curate fresh English names for the rest. This migration is intended as the first step toward eventually deprecating `eng_name` in favor of the Mobility-based translation.
- Q: Do the hand-curated/`eng_name`-sourced English project names require a separate formal approval step before the migration is applied to production? → A: No separate approval workflow — the requester will personally review the migration file (including the chosen English names) as part of normal code review before it is applied.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - English name available for every existing Project (Priority: P1)

Client applications that request project data in English (e.g. the Lalen and foreign-institution namespaces) must be able to read an English name for every one of the 47 existing diagnostic projects, not just newly created ones. Today, `Project.Name` only holds the Polish name, exactly the situation `Analyte.NameInReport` was in before it was translated.

**Why this priority**: This is the core deliverable explicitly requested — without backfilled English names for all current projects, the translation capability is technically present but practically useless, since every existing record would return blank/fallback English text.

**Independent Test**: After the data migration runs, switching `I18n.locale` to `:en` and reading `project.Name` for any of the 47 pre-existing projects returns a non-blank, sensible English name; switching back to `:pl` still returns the original Polish name unchanged.

**Acceptance Scenarios**:

1. **Given** a Project created before this feature existed (Polish name only in the native column), **When** the application reads `Name` under `I18n.locale = :pl`, **Then** the original Polish name is returned unchanged.
2. **Given** the same Project, **When** the application reads `Name` under `I18n.locale = :en`, **Then** an English translation is returned instead of the Polish text or a blank value.
3. **Given** all 47 Projects present in both the development and production databases, **When** the backfill migration has run, **Then** every one of the 47 Projects has exactly one English translation row.

---

### User Story 2 - Writing a Project name always keeps Polish as the source of truth (Priority: P2)

Following the exact convention already established for `Analyte#NameInReport`, whoever writes to `Project#Name` while the active locale is Polish must have that value land in the native `Projects.Name` column, not in the translations table — so Polish stays authoritative and undisturbed by translation infrastructure, and future schema/reporting code that reads the raw column keeps working unmodified.

**Why this priority**: This is a direct correctness requirement carried over from the Analyte precedent; getting it wrong would silently start storing Polish text as a "translation" row and could desynchronize the native column from reality.

**Independent Test**: With `I18n.locale = :pl`, assign a new value to `project.Name` and save; verify the native `Projects.Name` column changed and no new/duplicate `mobility_string_translations` row was created for the `:pl` locale on that project.

**Acceptance Scenarios**:

1. **Given** `I18n.locale = :pl`, **When** `project.Name = "Nowa nazwa"` is assigned and saved, **Then** the native `Projects.Name` column is updated to "Nowa nazwa" and no `:pl` row exists in `mobility_string_translations` for that project.
2. **Given** `I18n.locale = :en`, **When** `project.Name = "New name"` is assigned and saved, **Then** a row for locale `:en` is created or updated in `mobility_string_translations`, and the native `Projects.Name` column is left untouched.

---

### User Story 3 - Codebase is ready to translate User's FirstName, LastName, and Description (Priority: P3)

The User model (`FirstName`, `LastName`, `Description`) is a known upcoming translation target, but only the model-level readiness is in scope now — no backfill migration, no forced rollout. The goal is that when the team decides to activate translations for these three attributes, the model change is a small, well-understood, low-risk step that mirrors the pattern already validated on Analyte and Project.

**Why this priority**: Lowest priority because it explicitly excludes any data migration or production behavior change in this iteration — it's preparatory groundwork, not a user-facing capability yet.

**Independent Test**: Review the User model changes in isolation; confirm the three attributes are declared translatable using the same idiom as Analyte/Project, that existing User records are unaffected (no translation rows are auto-created), and that reading/writing `FirstName`, `LastName`, `Description` under the Polish locale continues to behave exactly as before this change.

**Acceptance Scenarios**:

1. **Given** the User model changes have been applied, **When** an existing user record is read under `I18n.locale = :pl` (the default), **Then** `FirstName`, `LastName`, and `Description` return the same values as before the change, with no behavior difference.
2. **Given** the User model changes have been applied, **When** no migration has been run to populate English values, **Then** reading any of the three attributes under `I18n.locale = :en` falls back gracefully (returns the Polish value or nil, matching the `default:` fallback convention) rather than raising an error.
3. **Given** the User model changes have been applied, **When** the test suite and application boot are exercised, **Then** no existing User-related functionality (authentication, `fullname`, serialization) breaks.

---

### Edge Cases

- What happens if a Project record has a blank/nil `Name` at backfill time? The migration must skip or handle it without raising, and must not create an English translation row with blank content (the `presence` Mobility plugin already treats blank as nil).
- What happens if a Project already has an `eng_name` column value (see existing `Projects.eng_name` string column) — should the backfill reuse it as a starting point for the English translation, or is `eng_name` unrelated legacy data to be left alone?
- What happens if the migration is run twice (e.g. re-run after a partial failure)? It must be idempotent — not create duplicate `:en` rows for the same Project (the existing unique index on `[translatable_id, translatable_type, locale, key]` already enforces this at the DB level, but the migration should not error out on a second run).
- What happens when a new Project is created after this feature ships, with only a Polish name supplied and no English name yet? Reading `Name` under `:en` should fall back to the Polish value (via the same `default:` proc pattern used for Analyte), not raise or return blank.
- Given `api_masdiag` serves eleven namespaces with different partner audiences, which callers actually read `Project.Name` under a non-`:pl` locale today, and could adding a translation layer change existing default-locale behavior for any of them? (Addressed by requiring default locale to remain `:pl` and native-column behavior unchanged — see FR-004.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `Project` model MUST declare `Name` as translatable via Mobility, using the same `key_value` string backend already configured for the application (the `mobility_string_translations` table), matching the declaration style used on `Analyte#NameInReport`.
- **FR-002**: Reading `Project#Name` under a locale for which no translation row exists MUST fall back to the native `Projects.Name` column value (mirroring Analyte's `default: -> { read_attribute(:Name) }` behavior), never raising or silently returning blank when Polish data exists.
- **FR-003**: Writing `Project#Name` with no explicit locale specified, or with an explicit Polish (`:pl`) locale, MUST write directly to the native `Projects.Name` column rather than creating/updating a `mobility_string_translations` row. **Implementation note (discovered during implementation, corrects the original wording)**: this MUST key off an explicit `locale:` keyword argument at the call site, not off the ambient `I18n.locale`/`Mobility.locale` — the application's `I18n.default_locale` is `:en` (config/application.rb), so a rule keyed on ambient locale would misroute an ordinary, locale-unaware write (e.g. `project.update!(Name: "x")` called under the app's default state) into the translations table instead of the native column. `Analyte#NameInReport=` has this same latent defect; it is out of scope for this feature to fix (see Assumptions).
- **FR-004**: Writing `Project#Name` MUST go through the normal Mobility translation backend, and MUST NOT modify the native `Projects.Name` column, only when the caller passes an explicit non-Polish `locale:` keyword argument (e.g. `locale: :en`) at the call site — not merely by the ambient locale being non-Polish at the time of the call.
- **FR-005**: A one-time data migration MUST populate an English (`:en` locale) translation for every Project record present in the database at migration time, using `I18n.locale = :en` when writing so the value lands in `mobility_string_translations` rather than the native column.
- **FR-006**: The migration's English names MUST be prepared in advance and MUST cover all 47 Projects that exist in the current development database, which mirrors the current production dataset. For each Project, the migration MUST source the English name from the existing `Projects.eng_name` column when that value is genuinely an English name (non-blank, not Polish text, not otherwise unreliable/placeholder content); for every other Project, the English name MUST be hand-curated (not auto-translated at migration runtime). The migration's data-preparation step MUST record which source (`eng_name` vs. hand-curated) was used per Project, to support later review.
- **FR-007**: The migration MUST be safe to re-run without creating duplicate English translation rows for a Project that already has one (idempotent upsert behavior).
- **FR-008**: The migration MUST NOT alter the native `Projects.Name` column for any record — Polish values remain the untouched source of truth in the native column.
- **FR-009**: The migration MUST handle a Project with a blank or nil `Name` without raising an error, and MUST NOT create an English translation row with empty content for such a record.
- **FR-010**: If a curated English name is not available for a given Project at migration time, the migration MUST either skip creating a translation row for that Project (relying on the existing fallback-to-Polish behavior) or flag it clearly in migration output — it MUST NOT invent a name silently or fail the entire migration for one missing entry.
- **FR-015**: The English names written by the migration (both `eng_name`-sourced and hand-curated) MUST be presented in the migration file itself in a clearly readable form (e.g. an explicit per-project mapping in the migration source, not an opaque generated file), so they can be reviewed by the requester as part of normal code review before the migration is applied to any shared environment — no separate formal sign-off workflow is required.
- **FR-011**: The `User` model MUST declare `FirstName`, `LastName`, and `Description` as translatable via Mobility using the same backend and idiom as Project/Analyte, with a `default:` fallback to the corresponding native column for each attribute.
- **FR-012**: The User model changes in this iteration MUST NOT include a data migration, MUST NOT create any `mobility_string_translations` rows for existing users, and MUST NOT alter the native `Users.FirstName`, `Users.LastName`, or `Users.Description` column values or the default read/write behavior when the active locale is Polish.
- **FR-013**: Existing functionality that depends on `User#FirstName`, `User#LastName`, or `User#Description` (including `fullname`, authentication flows, and any serializers/resources exposing these fields) MUST continue to behave identically to before this change when read under the default (Polish) locale.
- **FR-014**: All full existing automated test suites (for `Analyte`, `Project`, `User`, and any request specs touching Project or User data) MUST continue to pass after these changes, with new tests added to cover the Project translation read/write behavior described in FR-002 through FR-004.

### Key Entities

- **Project**: Represents a diagnostic test project (e.g. "Toxoplasma gondii IgG"). Existing native attribute `Name` (Polish, required) gains an English translation counterpart stored in the shared translations table; the existing `eng_name` column is a separate, pre-existing attribute whose relationship to this new translation must be clarified during planning (see Assumptions).
- **Translation record** (`mobility_string_translations`, existing shared/polymorphic table): One row per `(translatable_type, translatable_id, locale, key)` — already used by `Analyte`; this feature adds `Project` (and later `User`) as additional `translatable_type` values sharing the same table, keyed by attribute name (`Name`, `FirstName`, `LastName`, `Description`).
- **User**: Represents an application user/operator. Native attributes `FirstName`, `LastName`, `Description` (all currently Polish/untranslated) become translatable in this iteration at the model-declaration level only — no translated data is populated yet.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the 47 existing Project records have a readable, non-blank English name immediately after the migration runs, verifiable by iterating all Projects under `I18n.locale = :en`.
- **SC-002**: Reading any Project's `Name` under the Polish locale returns byte-for-byte the same value before and after this feature ships, for all 47 existing records — zero regressions in the Polish (default) data path.
- **SC-003**: Running the backfill migration a second time produces zero additional or duplicate translation rows (idempotency verified by row count before/after re-run).
- **SC-004**: All pre-existing automated tests continue to pass with zero regressions, and new tests covering Project's translated-read, Polish-write, and English-write behavior are green.
- **SC-005**: No behavior change is observable in any User-related feature (login, `fullname`, any endpoint serializing user data) when exercised under the default locale after the User model changes ship — confirmed by the existing User-related test suite passing unmodified.

## Assumptions

- The target audience/purpose for `Project`'s English name is analogous to `Analyte#NameInReport`'s: surfacing project names to non-Polish-speaking partner institutions (e.g. Lalen, foreign/`fv1` namespace clients) — no specific endpoint or serializer change is requested by the user, so exposing the translated value through the API is treated as a separate, potential follow-up rather than in-scope here.
- The existing `Projects.eng_name` string column is read (not written) by the migration as a candidate source of English names, used only where its content is verifiably an actual English name; the native `eng_name` column itself is left unmodified by this feature (no schema change, no deletion). Determining "genuinely an English name" (vs. blank, Polish, or garbage data) is a data-preparation judgment call made once, by hand or with tooling, before the migration runs — not a runtime heuristic in the migration code itself. This migration is understood to be the first step toward eventually deprecating application-level usage of `eng_name` in favor of the Mobility-based translation, though retiring/removing the `eng_name` column itself is explicitly out of scope for this feature (a schema change to a shared LabSample table requires its own explicit confirmation per repository policy).
- "Development database has 47 Projects, matching production" is taken as a factual, stable count as of this spec's creation; the migration targets whatever Project records exist at the time it runs (not hardcoded to exactly 47), so it remains correct even if the count has shifted slightly by execution time.
- Curated English project names will be authored by the assistant during implementation, consistent with "przygotowanych przez Ciebie angielskich nazw" (names prepared by the assistant) in the original request. No separate formal approval workflow is required; the requester reviews the migration file itself (including the chosen names, and their source per FR-006/FR-015) as part of normal code review before it is applied to any shared environment.
- **Correction found during implementation**: this Assumption originally (incorrectly) stated the application's default `I18n.locale` is `:pl`. It is actually `:en` (`config.i18n.default_locale = :en` in `config/application.rb`), and the test suite explicitly sets `I18n.locale = :en` before every example (`spec/rails_helper.rb`). This feature does not change the default locale or add any locale-switching mechanism to the request pipeline — but FR-003/FR-004's mechanism had to be designed around this actual default (see those requirements' implementation notes) rather than the originally-assumed one.
- Per project convention (see repository CLAUDE.md), `Projects` and `Users` are tables in the shared LabSample database used by multiple independent applications. Adding Mobility translation to these models involves no schema change (no new/altered/dropped column, since `mobility_string_translations` already exists and is polymorphic/generic) — only new rows in an existing shared table and new model code in `api_masdiag`. This is called out explicitly because any future change that *did* alter the `Projects` or `Users` table schema would require the explicit-confirmation and cross-app-impact process already mandated for this shared database.
- No migration, rollout, or data population for `User` translations is performed in this iteration — User Story 3 is model-readiness only, per explicit user instruction ("na razie bez migracji" — no migration for now).
- **Finding, flagged but explicitly out of scope for this feature**: `Analyte#NameInReport=` (pre-existing code, not touched by this feature) has the same latent defect that FR-003 originally described — it keys off ambient `Mobility.locale` rather than an explicit `locale:` keyword, so a hypothetical bare `Analyte.create(NameInReport: "x")` called under the application's actual default locale (`:en`) would silently fail to write the native column (NOT NULL violation) instead of raising a more obvious error earlier. This has not caused a failure to date because every existing `Analyte`-creating call site (specs and, per a repository search, application code) happens to wrap in `I18n.with_locale(:pl)` explicitly. This feature deliberately does not modify `Analyte`; the user has been informed and may wish to apply the same fix there in a separate, dedicated change.
