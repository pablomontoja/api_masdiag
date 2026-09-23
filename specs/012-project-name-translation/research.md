# Phase 0 Research: Project and User Attribute Translation

No unresolved `NEEDS CLARIFICATION` markers remained in Technical Context — this feature replicates an existing, working pattern (`Analyte#NameInReport`) rather than introducing new technology. The items below document the concrete decisions made and their rationale, for traceability.

## Decision: Reuse the existing `key_value` Mobility backend, no new backend/config

**Rationale**: `config/initializers/mobility.rb` already configures `backend :key_value` with `active_record`, `reader`, `writer`, `backend_reader`, `query`, `cache`, `presence`, and `default nil` plugins, backing the polymorphic `mobility_string_translations` table. `Analyte#NameInReport` already proves this configuration works correctly for the hybrid "native column = Polish, translation table = other locales" pattern this feature needs. Introducing a second backend or table would fragment translation storage for no benefit.

**Alternatives considered**:
- A dedicated `Project` translation table (Mobility's `table` backend) — rejected: inconsistent with the existing `Analyte` convention and the polymorphic table already exists for exactly this purpose.
- Storing English name in a new column (e.g. widening `eng_name`'s role) — rejected: this is precisely the schema-change-to-a-shared-table path the repository's CLAUDE.md requires explicit user confirmation for, and the whole point of this feature is to move *away* from ad hoc columns like `eng_name` toward the Mobility convention.

## Decision: Setter override pattern — `:pl` writes bypass Mobility, all other locales go through it

**Rationale**: Copied verbatim in spirit from `Analyte#NameInReport=`:

```ruby
def NameInReport=(value, locale: nil, **options)
  if (locale&.to_sym || Mobility.locale) == :pl
    write_attribute(:NameInReport, value)
  else
    super(value, locale: locale, **options)
  end
end
```

This keeps the native column as the single source of truth for Polish (required by FR-003/FR-008 and by every other app reading `Projects.Name` directly via the shared LabSample database, which has no knowledge of Mobility or the translations table).

**Alternatives considered**:
- Rely on Mobility's `fallthrough_accessors` / `column_fallback` plugins to do this automatically — rejected: those plugins are explicitly commented out/disabled in the shared initializer (per the research fork's findings), and enabling them project-wide would be a broader behavioral change affecting `Analyte` too, out of scope for this feature and riskier than a per-model override already proven to work.

**⚠️ Superseded during implementation**: the `locale == :pl` check shown above (copied verbatim from `Analyte`) turned out to be broken for `Project`/`User`. The application's `I18n.default_locale` is `:en` (`config/application.rb`), and the test suite sets `I18n.locale = :en` ambiently before every example (`spec/rails_helper.rb`). Since `Mobility.locale` follows ambient `I18n.locale` when no explicit `locale:` kwarg is given, the literal-`:pl`-check override routed every *ordinary, locale-unaware* write (e.g. a bare `create(:project, Name: "x")`, used across 33 spec files) into Mobility instead of the native column, causing a `NOT NULL` violation on `Projects.Name` (broke 430 previously-passing examples when first run against the full suite). `Analyte#NameInReport=` has the identical defect, just never exercised, because every `Analyte`-creating call site happens to already wrap in `I18n.with_locale(:pl)` explicitly.

**Corrected implementation** (`Project#Name=`, and equivalently for `User`'s three attributes):

```ruby
def Name=(value, locale: nil, **options)
  explicit_locale = locale&.to_sym
  if explicit_locale.nil? || explicit_locale == :pl
    write_attribute(:Name, value)
  else
    super(value, locale: locale, **options)
  end
end
```

The rule now keys off an **explicit `locale:` keyword argument at the call site**, not ambient global state: no explicit locale (the common case — ordinary factory/application code) or an explicit `:pl` both mean "native column, since that's the true default regardless of what `I18n.default_locale` happens to be app-wide." Only an explicit non-`:pl` `locale:` kwarg (e.g. `locale: :en`) routes to Mobility. This makes the backfill migration's write call (see below) need to pass that kwarg explicitly rather than relying on `I18n.with_locale(:en) { ... }`, since the latter has no explicit kwarg and would now (correctly) be treated as a native-column write.

## Decision: Backfill migration sources English names from `eng_name` where genuine, hand-curated elsewhere

**Rationale**: Per the clarification session (2026-09-23), a live query of the development database's 47 Projects shows `eng_name` values fall into three buckets:
1. **Genuine English translations** — e.g. "Vitamin D metabolites", "Aminoacids", "Purines and Pyrimidines" → use directly.
2. **Bare acronyms identical in Polish and English** — e.g. "AED", "CBD", "TSH", "HbA1c" → technically usable as-is (no translation needed), treated as genuine.
3. **Blank, or not an actual name** — e.g. Project 4 ("Archiwum" → blank), 43–45 (blank), and Project 7 ("Panel substancji psychoaktywnych" → `eng_name` "TOXO", which reads as an internal code/category label rather than an English translation of the Polish name) → these require hand-curated English names.

This judgment call is made once, by hand, while authoring the migration's data mapping — not as runtime logic in the migration itself (per FR-006's requirement that source determination is a data-preparation step, not a runtime heuristic).

**Alternatives considered**:
- Auto-translate via an external translation API at migration runtime — explicitly rejected by the original request ("nie" implied by "przygotowanych przez Ciebie... nazw", i.e. names prepared in advance, not generated live) and by FR-006's "not auto-translated at migration runtime" requirement.
- Treat all `eng_name` values as reliable without review — rejected per clarification answer: "użyj eng_name jako źródło nazw **jeżeli rzeczywiście nazwa jest po angielsku**" (only if the name is genuinely in English).

## Decision: Migration writes via an explicit `locale:` keyword argument, not `I18n.with_locale`

**Rationale**: Writing through the model exercises the same `Project#Name=` setter path production code uses, guaranteeing the migration produces rows in exactly the shape/format Mobility expects, without duplicating its internal key-value table logic by hand.

**⚠️ Superseded during implementation**: the originally planned `I18n.with_locale(:en) { project.update!(Name: english_name) }` pattern (matching the user's request phrasing, "używając I18n.locale = :en") turned out to be indistinguishable, at the setter's signature level, from an ordinary ambient-locale write with no translation intent — both arrive at `Name=` with no explicit `locale:` kwarg. Once the setter override was corrected (see the setter-override decision above) to key off the explicit kwarg rather than ambient state, `I18n.with_locale(:en) { project.update!(...) }` would silently write to the *native* column instead of the translations table, which would have made the migration a no-op.

**Corrected implementation**:

```ruby
project.public_send(:Name=, english_name, locale: :en)
project.save!
```

This passes the `locale:` kwarg explicitly, so it is unambiguous under the corrected setter logic — it must go through Mobility. `public_send` (rather than `project.Name = ...`) is needed because Ruby's `attr=` assignment syntax cannot pass keyword arguments; Mobility's own generated accessors and `Analyte`'s precedent do not need this in existing code only because nothing outside this migration writes a translation value with an explicit locale today.

**Alternatives considered**:
- Raw `ActiveRecord::Base.connection.execute` INSERT into `mobility_string_translations` — rejected: brittle (duplicates internal Mobility table structure knowledge), harder to keep idempotent safely, and not what was requested.

## Decision: Idempotency confirmed via `db:migrate:redo`, relying on the existing unique index

**Rationale**: FR-007 requires the migration to be safe to re-run. Writing through the model layer, combined with Mobility's own unique index (`[translatable_id, translatable_type, locale, key]`, already present per the existing `create_string_translations` migration), means a second run updates the existing row to the same value rather than inserting a duplicate. **Verified empirically** during implementation via `bin/rails db:migrate:redo:primary VERSION=20260923120000` against the development database: 47 `Project`/`:en` rows before the redo, 47 after — no duplicates, no data loss. (A first redo attempt failed on the migration's `down` method — see the migration file's own history — due to `key` being an unquoted MySQL reserved word in the raw `DELETE` SQL; fixed by backtick-quoting it, then successfully re-verified.)

## Decision: `User` translation declaration only — no data migration

**Rationale**: Explicit instruction: "na razie bez migracji" (no migration for now). The `translates` declaration alone, with a `default:` fallback proc to the native column (same idiom as `Analyte`/`Project`), changes zero runtime behavior for existing callers under the default `:pl` locale — reads fall through to `read_attribute`, and no `mobility_string_translations` rows are ever created without an explicit non-Polish write, which nothing in the current codebase performs for `User` yet.

**Alternatives considered**: None — this was an explicit, unambiguous scope boundary in the original request.
