# Phase 1 Data Model: Project and User Attribute Translation

No schema changes. All entities below already exist in the shared LabSample database; this feature adds Mobility model declarations and (for `Project`) new rows in the pre-existing `mobility_string_translations` table. Per repository policy, any actual schema change to a shared LabSample table requires explicit user confirmation — none is needed or proposed here.

## Project (existing table `Projects`, unchanged schema)

| Attribute | Type | Translation status after this feature |
|---|---|---|
| `Id` | integer, PK | unchanged |
| `Name` | text, not null | **translatable** — Polish stays in this column (source of truth); English lives in `mobility_string_translations` |
| `eng_name` | string(255) | unchanged column; read-only as a *migration data source*, not wired into Mobility, not deprecated/removed in this feature |
| *(all other existing columns)* | — | unchanged |

**Validation rules**: No new validation added. `Name`'s existing `null: false` DB constraint is untouched — the Mobility setter override always writes the Polish value straight to the native column, so the not-null constraint continues to be satisfiable exactly as before.

**State/lifecycle**: No new states. A `Project`'s "has an English translation" status is derived (does a `mobility_string_translations` row exist for `key: "Name", locale: "en"`), not stored as a flag.

## User (existing table `Users`, unchanged schema)

| Attribute | Type | Translation status after this feature |
|---|---|---|
| `Id` | integer, PK | unchanged |
| `FirstName` | text | **translatable** — Polish stays in this column; no data migration in this iteration |
| `LastName` | text | **translatable** — Polish stays in this column; no data migration in this iteration |
| `Description` | text | **translatable** — Polish stays in this column; no data migration in this iteration |
| *(all other existing columns, including `type`, `Login`, `email`, etc.)* | — | unchanged |

**Validation rules**: None added.

**State/lifecycle**: No new states in this iteration — zero `mobility_string_translations` rows are created for `User` by this feature (model declaration only, per explicit scope boundary).

## Translation record (existing table `mobility_string_translations`, unchanged schema, polymorphic)

Already used by `Analyte`. This feature adds `Project` (and, once a future migration exists, `User`) as additional values of `translatable_type`.

| Column | Meaning for this feature |
|---|---|
| `translatable_type` | `"Project"` (new) or `"User"` (declared, not populated yet) |
| `translatable_id` | `Projects.Id` / `Users.Id` |
| `key` | `"Name"` for Project; `"FirstName"` / `"LastName"` / `"Description"` for User (once populated) |
| `locale` | `"en"` for the rows this feature's migration creates (Polish never gets a row, by design — see FR-003) |
| `value` | The English name/text |

**Uniqueness**: Enforced by the existing unique index `index_mobility_string_translations_on_keys` on `[translatable_id, translatable_type, locale, key]` — guarantees the backfill migration cannot create duplicate English rows for the same Project even under a naive re-run, and is the DB-level backstop behind FR-007's idempotency requirement.

## Relationships

No new associations required beyond what Mobility's `active_record` plugin already provides generically (`project.string_translations`, matching the existing `analyte.string_translations` used in `spec/models/analyte_spec.rb`). No foreign keys change; `translatable_type`/`translatable_id` is a polymorphic reference, not an FK constraint, consistent with how `Analyte` already uses this table.

## Migration data mapping (Project → English name, source)

Prepared during Phase 1 for use in the Phase 2 migration task. Source column legend: **E** = taken from `Projects.eng_name` (verified genuinely English), **C** = hand-curated (eng_name blank, non-English, or an unreliable category label rather than a translation).

| Id | Polish `Name` | English name to write | Source |
|---|---|---|---|
| 1 | Przesiew | Newborn Screening | C *(eng_name "NBS" is an acronym for the English term, not a full name — expanded for clarity)* |
| 2 | Witamina D | Vitamin D metabolites | E |
| 3 | Aminokwasy | Aminoacids | E |
| 4 | Archiwum | Archive | C *(eng_name blank)* |
| 5 | AED | AED | E *(acronym, identical in both languages)* |
| 6 | CBD | CBD | E *(acronym, identical in both languages)* |
| 7 | Panel substancji psychoaktywnych | Psychoactive Substances Panel | C *(eng_name "TOXO" is an internal category code, not a translation)* |
| 8 | EDX | EDX | E *(acronym, identical in both languages)* |
| 9 | Przeciwciała anty-SARS-CoV-2 | anty-SARS-CoV-2 antibodies | E |
| 10 | Witamina A, E oraz Q10 | Vitamin A, E and Coenzyme Q10 | E |
| 11 | CBD/THC | THC | C *(eng_name "THC" only covers half the Polish name; written as "CBD/THC" for consistency)* — **English name to write: CBD/THC** |
| 12 | Homocysteina | Homocysteine | E |
| 13 | Borreliosis Screening | Borreliosis Screening | E *(already English)* |
| 14 | TSH | TSH | E *(acronym, identical in both languages)* |
| 15 | Profil Kwasów Organicznych | Organic acid profile | E |
| 16 | Puryny i pirymidyny | Purines and Pyrimidines | E |
| 17 | SAICAr i S-Ado | SAICAr and S-Ado | E |
| 18 | Acylokarnityny | Acylcarnitines | E |
| 19 | Borreliosis Confirmation | Borreliosis Confirmation | E *(already English)* |
| 20 | Metanefryny | Methanephrines | E |
| 21 | Kwasy OMEGA | OMEGA Acids | E |
| 22 | Wit D BASIC | Vitamin D | E |
| 23 | HbA1c | HbA1c | E *(acronym, identical in both languages)* |
| 24 | Nietolerancja histaminy | Histamine Intolerance | E |
| 25 | 3-OMD TEST | 3-OMD TEST | E *(acronym, identical in both languages)* |
| 26 | Indeks Glutationu | Glutathione Index | C *(eng_name "GSSG:GSH_ratio" is a technical ratio label, not a translation of "Indeks Glutationu")* |
| 27 | PEth - Fosfatydyloetanol | Phosphatidylethanol | E |
| 28 | Goldcup TOX | Goldcup TOX | E *(already English)* |
| 29 | Jod w moczu | Iodine in urine | E |
| 30 | Deficyt arginazy | Arginase deficiency | E |
| 31 | Toksykologia | Toxicology | E |
| 32 | Metale w moczu | Metals in urine | E |
| 33 | LPC pochodne VLCFA | ALD-X | C *(eng_name "ALD-X" is a product/panel code, not a translation — kept as-is since it is the recognized English-facing name for this panel)* |
| 34 | OMEGA BASIC | OMEGA Acids Basic | E |
| 35 | Lizosfingomieliny | Lysosphingomyelins | C *(eng_name "Lyso" is an abbreviation, not a full translation)* |
| 36 | NAD | NAD | E *(acronym, identical in both languages)* |
| 37 | Profil aminokwasów w moczu | Amino acid profile in urine | E |
| 38 | Profil steroidowy | Steroid profile | E |
| 39 | Analiza toksykologiczna ilościowa (LC-MS/MS) | Quantitative toxicological analysis | E |
| 40 | Analiza toksykologiczna jakościowa (LC-MS/MS) | Qualitative toxicological analysis | E |
| 41 | Analiza toksykologiczna typu "GHB" (LC-MS/MS) | "GHB" toxicological analysis | E |
| 42 | Analiza toksykologiczna na zlecenie | Custom Toxicological Analysis | E |
| 43 | LysoGb1 | LysoGb1 | C *(eng_name blank; Polish name is already an English-style identifier)* |
| 44 | LysoGb3 | LysoGb3 | C *(eng_name blank; Polish name is already an English-style identifier)* |
| 45 | Magnez | Magnesium | C *(eng_name blank)* |
| 46 | PAGN | PAGN | E *(acronym, identical in both languages)* |
| 47 | PAGN w moczu | PAGN in urine | E |

**Note for implementation**: Rows marked E are copied verbatim from the current `eng_name` column value at implementation time; the migration task must re-read `eng_name` from the actual target database at run time (not hardcode the value shown here) for the **E** rows, since `eng_name` is the authoritative source per FR-006 — this table exists to record *which* rows are E vs. C and to supply the exact text for **C** rows, not to freeze a snapshot for E rows. Row 11's final decision (kept as "CBD/THC" rather than reusing "THC") and row 33/35's category-code judgment calls should be re-confirmed by the requester during migration code review (per FR-015), since these are the least certain cases.
