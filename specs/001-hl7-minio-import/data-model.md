# Data Model: HL7 MinIO Import

## New Table: `hl7_imports`

```ruby
create_table :hl7_imports do |t|
  # Linked measurement (nullable - may be nil when awaiting_registration)
  t.integer :measurement_id

  # MinIO source file metadata
  t.string  :s3_key,    null: false
  t.string  :s3_bucket
  t.string  :s3_etag
  t.integer :file_size

  # Parsed HL7 message metadata (populated after processing)
  t.string   :control_id
  t.string   :message_type
  t.datetime :message_datetime
  t.string   :sending_application
  t.string   :sending_facility
  t.string   :external_order_id    # OBR-3 filler order number
  t.string   :hl7_test_code        # OBR-4 test code (e.g. "UCR,usEssEl,UsMetox")
  t.string   :kit_code_extracted   # OBR-13 or PID-5 barcode

  # Processing lifecycle
  t.integer  :status,          null: false, default: 0
  t.datetime :processed_at
  t.text     :error_message
  t.json     :processing_stats    # { analytes_created: N, analytes_skipped: N, warnings: [] }
  t.integer  :retry_count,    default: 0
  t.datetime :last_retry_at

  t.timestamps
end

add_index :hl7_imports, :s3_key,         unique: true
add_index :hl7_imports, :measurement_id, unique: true
add_index :hl7_imports, :status
add_index :hl7_imports, :kit_code_extracted
add_index :hl7_imports, :created_at

add_foreign_key :hl7_imports, "Measurements", column: :measurement_id, primary_key: "Id"
```

**Status enum values**:
```ruby
enum :status, {
  pending:               0,   # created, waiting for processing job
  processing:            1,   # job is actively running
  completed:             2,   # analytes imported successfully
  failed:                3,   # HL7 parse or DB error
  awaiting_registration: 4,   # no matching Measurement found yet
  registration_error:    5,   # duplicate or conflict
  retry_scheduled:       6    # picked up by Hl7RetryFailedJob, will be re-enqueued
}
```

## New Model: `Hl7Import`

```
app/models/hl7_import.rb
```

Key associations:
- `belongs_to :measurement, class_name: "Measurement", foreign_key: :measurement_id, primary_key: "Id", optional: true`
- `has_one_attached :hl7_file`

Key instance methods:
- `mark_completed!(stats)` — sets status: :completed, processed_at, processing_stats
- `mark_failed!(message)` — sets status: :failed, error_message
- `mark_awaiting_registration!(reason)` — sets status: :awaiting_registration, error_message
- `mark_registration_error!(reason)` — sets status: :registration_error, error_message

Key scopes:
- `ready_for_retry` — `where(status: :failed).where("retry_count < 3")` (used by `Hl7RetryFailedJob`)

**Retry lifecycle**: `Hl7RetryFailedJob` sets `status: :retry_scheduled` and increments `retry_count`, then enqueues `Hl7::MeasurementImportJob`. If the import fails again, the importer calls `mark_failed!` setting status back to `:failed`. On the next retry cycle, if `retry_count < 3` the record is picked up again. After 3 failed attempts `retry_count = 3` causes `ready_for_retry` to stop returning it — the import stays `:failed` for manual investigation.

**Nullable unique index on `measurement_id`**: MySQL treats multiple NULLs as distinct in a unique index, so many `awaiting_registration` records (all with `measurement_id = NULL`) coexist safely. Once linked, uniqueness prevents two imports from sharing the same measurement.

## Modified Models (existing)

### Measurement

Add association:
```ruby
has_one :hl7_import, class_name: "Hl7Import", foreign_key: :measurement_id, primary_key: "Id"
```

### Result (no schema change)

The `Result` record (PK = `MeasurementId`) is created by the importer as part of the processing flow. No model changes needed.

## New Constants Module: `Hl7::Config`

```
app/lib/hl7/config.rb
```

```ruby
module Hl7
  module Config
    ARCHIVE_FOLDER = "archive"
    SYSTEM_USER_ID = nil  # ⚠️ BLOCKER: must be set before first import — integer ID of system user for Result.ImportUserId
    #   Find with: User.find(24) or check Cerascreen::Labordatenbank::ResultImporterJob

    # Maps HL7 OBR-4 first component (before first ^) → ProjectId
    TEST_MAPPING = {
      "UCR,usEssEl,UsMetox"              => 32,  # NutriPATH urine metals / essential elements / metox panel
      "UR-IODINE,uIodEx,UIodCom,usCr"   => 29   # NutriPATH urine iodine panel
    }.freeze

    # Maps HL7 OBX-3 first component (before first ^) → Analyte.NameInAPI
    #
    # Key conventions:
    #   - Plain key (e.g. "42220-4")          → raw/absolute analyte; value converted from ug/gCR to µg/L
    #   - "_crea" suffix (e.g. "42220-4_crea") → creatinine-normalized variant; value stored directly as-is
    #   - Identifiers in UG_PER_L_DIRECT_IDENTIFIERS (e.g. "UR-IODINE") → already in ug/L, stored as ng/ml (1:1)
    #
    # HL7 files may contain analytes not in this mapping — they are silently skipped.
    ANALYTE_MAPPING = {
      # ── Project 32: NutriPATH Urine Metals ──────────────────────────────────

      # Creatinine (Project 32)
      "UCR"      => "krea",    # CREATININE Urine Spot (mmol/L → converted to mg/dl: × 113.12 / 10)
      "CrSpUr"   => "krea",    # Creatinine, Spot Urine (duplicate segment, same conversion)

      # Raw absolute concentration analytes (Unit: µg/L in DB)
      # Value in HL7 is ug/gCR → converted to µg/L by importer
      "42220-4"  => "chromium",   # Chromium (Cr)
      "34270-9"  => "cobalt",     # Cobalt (Co)
      "13829-7"  => "copper",     # Copper (Cu)
      "13465-0"  => "mercury",    # Mercury (Hg)
      "13466-8"  => "lead",       # Lead (Pb)
      "13470-0"  => "aluminium",  # Aluminum (Al)
      "13463-5"  => "arsenic",    # Arsenic-total (As)
      "56651-3"  => "cadmium",    # Cadmium (Cd)
      "13472-6"  => "nickel",     # Nickel (Ni)

      # Zinc: HL7 value is in mg/gCR → conversion uses ×1000 factor before creatinine multiplication
      "13473-4"  => "zinc",       # Zinc (Zn), HL7 unit: mg/gCR

      # Creatinine-normalized analytes (Unit: µg/g crea in DB)
      # Value in HL7 is ug/gCR → stored directly (no conversion needed)
      "42220-4_crea" => "chromium_crea",
      "34270-9_crea" => "cobalt_crea",
      "13829-7_crea" => "copper_crea",
      "13465-0_crea" => "mercury_crea",
      "13466-8_crea" => "lead_crea",
      "13470-0_crea" => "aluminium_crea",
      "13463-5_crea" => "arsenic_crea",
      "56651-3_crea" => "cadmium_crea",
      "13472-6_crea" => "nickel_crea",
      "13473-4_crea" => "zinc_crea",  # HL7 unit: mg/gCR; stored as mg/g crea directly

      # ── Project 29: NutriPATH Urine Iodine ──────────────────────────────────

      # Creatinine (Project 29) — same HL7 code as Project 32 creatinine but different NameInAPI
      # The importer resolves the correct analyte by scoping lookup to the current ProjectId
      "usCr"      => "kreatinin_iu",   # Creatinine, Urine Spot (mmol/L → converted to mg/dl: × 113.12 / 10)

      # Iodine creatinine-normalized (Unit: ug/g creatinine in DB)
      # Value in HL7 is ug/gCR → stored directly
      "uIodEx"    => "jod_krea_iu",    # Urine Iodine Corrected (ug/gCR → direct)

      # Iodine absolute (Unit: ng/ml in DB)
      # Value in HL7 is ug/L; conversion: 1 ug/L = 1 ng/ml (numerically identical)
      "UR-IODINE" => "iodine_ng_ml",   # URINE IODINE (ug/L → ng/ml, factor 1:1)
    }.freeze

    # Molar mass of creatinine in g/mol — used for ug/gCR → µg/L AND mmol/L → mg/dl conversions
    CREATININE_MOLAR_MASS = 113.12
    # mmol/L → mg/dl: value_mg_dl = mmol_per_L × CREATININE_MOLAR_MASS / 10

    # HL7 OBX-3 identifiers whose values are already in ug/L (absolute) and map to ng/ml DB units
    # Conversion: 1 ug/L = 1 ng/ml (factor 1:1; no arithmetic needed, just label change)
    UG_PER_L_DIRECT_IDENTIFIERS = %w[UR-IODINE].freeze
  end
end
```

## Creatinine Conversion Logic (for `Hl7::MeasurementImporter`)

### Background

The NutriPATH HL7 file reports analyte concentrations in two ways:
- `ug/gCR` — micrograms per gram of creatinine (creatinine-normalized)
- `mg/gCR` — milligrams per gram of creatinine (Zinc in this panel)

The database stores two variants for each metal analyte:
- **Raw absolute concentration** (`Unit: "µg/l"` or `"µg/L"`) — must be computed
- **Creatinine-normalized** (`Unit: "µg/g crea"`) — stored directly from HL7

### Conversion Formula

The unit factor is read from **OBX-6** in the HL7 file — not from a static identifier list in config:

```
# Step 1: convert creatinine from mmol/L (HL7) to mg/dl (DB) and g/L (for metal back-conversion)
creatinine_mg_dl  = creatinine_mmol_L × CREATININE_MOLAR_MASS / 10       # stored in DB
creatinine_g_per_L = creatinine_mmol_L × CREATININE_MOLAR_MASS / 1000    # used for ug/gCR → µg/L

# Step 2: convert metal analytes using OBX-6 unit
obx_unit = obx[6].to_s.strip.downcase   # e.g. "ug/gcr" or "mg/gcr"

# For ug/gCR analytes (OBX-6 == "ug/gcr"):
value_µg_per_L = hl7_value × creatinine_g_per_L

# For mg/gCR analytes (OBX-6 == "mg/gcr"):
value_µg_per_L = hl7_value × 1000 × creatinine_g_per_L
```

### Example (from sample HL7 file)

```
Creatinine: 11.4 mmol/L
creatinine_mg_dl   = 11.4 × 113.12 / 10    = 128.96 mg/dl  ← stored in DB as krea / kreatinin_iu
creatinine_g_per_L = 11.4 × 113.12 / 1000  = 1.2896 g/L    ← used for metal back-conversion

OBX: Chromium, value = 0.14, OBX-6 = "ug/gCR"
chromium_µg_per_L = 0.14 × 1.2896 = 0.1805 µg/L

OBX: Zinc, value = 0.21, OBX-6 = "mg/gCR"
zinc_µg_per_L = 0.21 × 1000 × 1.2896 = 270.8 µg/L
```

### Implementation Notes

- Creatinine OBX (identifier `UCR`, `CrSpUr`, or `usCr`) is extracted first, before processing other analytes
- The raw mmol/L value is converted to mg/dl for DB storage: `mmol_L × 113.12 / 10`
- The same mmol/L value is separately converted to g/L for use in metal back-conversion: `mmol_L × 113.12 / 1000`
- If creatinine is missing or zero AND the project requires absolute conversion (Project 32), the import MUST fail
- For Project 29, creatinine is stored but not used for back-conversion — iodine absolute value arrives pre-computed in ug/L
- The **mg/gCR vs ug/gCR** distinction is determined by reading OBX-6 (the unit field) at runtime — not by checking the OBX-3 identifier against `MG_PER_G_CR_IDENTIFIERS`. This makes the logic self-documenting and robust to new analytes without config changes.
- The importer processes each NM-type OBX segment TWICE when a matching raw analyte AND a `_crea` analyte both exist (Project 32 metals):
  1. Once with the HL7 code directly (e.g. `"42220-4"`) → converts to µg/L using OBX-6 unit → `chromium`
  2. Once with the `_crea` suffix key (e.g. `"42220-4_crea"`) → stores raw HL7 value directly → `chromium_crea`
- For `_crea` analytes: the stored value is the raw HL7 value as-is (ug/gCR or mg/gCR — no conversion)
- For `UG_PER_L_DIRECT_IDENTIFIERS` (e.g. `UR-IODINE`): value is already in ug/L; stored directly as ng/ml (1:1 numeric equivalence: 1 µg/L = 1 ng/ml)

## New Services

### `Hl7::MinioScanner`
```
app/services/hl7/minio_scanner.rb
```
- Connects to dedicated HL7 S3 bucket via `credentials.dig(:hl7_s3, ...)`
- Lists objects, filters out `archive/` prefix and already-imported `s3_key` values
- Downloads each file, calls `parse_hl7_metadata`, creates `Hl7Import`, links to `Measurement` or marks awaiting
- Barcode extraction: OBR-13 first, fallback to PID-5 first component

### `Hl7::MeasurementImporter`
```
app/services/hl7/measurement_importer.rb
```
- Plain service object (not `ApplicationService`) — initialized with `Hl7Import`, called via `#import` → returns `true/false`
- Receives an `Hl7Import` record (already linked to a `Measurement`)
- Downloads HL7 file via ActiveStorage
- Parses MSH/OBR/OBX using ruby-hl7 gem
- Extracts creatinine value from the first NM-type OBX whose identifier is in `{ "UCR", "CrSpUr", "usCr" }` — for projects requiring absolute conversion (Project 32), fails if creatinine is missing or zero
- For each remaining NM-type OBX: looks up the plain key in `ANALYTE_MAPPING`; if found AND a `CODE_crea` key also exists, processes the segment twice (raw → absolute µg/L; `_crea` → direct store)
- For `UG_PER_L_DIRECT_IDENTIFIERS` (e.g. `UR-IODINE`): stores value directly (1 ug/L = 1 ng/ml, no arithmetic)
- Looks up analytes by `NameInAPI` scoped to `ProjectId` (resolved from `Hl7::Config::TEST_MAPPING[hl7_test_code]`)
- Creates `Result` record (`Results` table, PK = `MeasurementId`) if not already present; sets `ImportUserId = Hl7::Config::SYSTEM_USER_ID`
- Bulk-inserts `AnalyteResult` rows (replaces existing for same `ResultId`)
- Updates `Measurement.Status = 4, MeasureDate`
- Archives file in MinIO (copy to `archive/`, delete original) — outside transaction, failure does not roll back import
- On error: calls `hl7_import.mark_failed!(message)`, returns `false`

### `Hl7::PendingImportLinker`
```
app/services/hl7/pending_import_linker.rb
```
- Iterates `Hl7Import.where(status: :awaiting_registration)` via `find_each`
- For each: looks up `Sample.find_by(Code: kit_code_extracted)`, then `measurements.find_by(ProjectId: project_id)`
- On match: links `measurement_id`, updates status to `:pending`, enqueues `Hl7::MeasurementImportJob`
- Unknown test code → marks `:registration_error`
- No sample or measurement yet → increments `still_waiting`, leaves status unchanged
- Returns `{ linked:, waiting:, errors: }` summary hash

## New Jobs

### Scheduled (Solid Queue recurring tasks)

Three flat (top-level, non-namespaced) job classes are used as Solid Queue recurring task entry points. Solid Queue requires class names in `config/solid_queue.yml` to match top-level constants:

#### `Hl7MinioScannerJob`
```
app/jobs/hl7_minio_scanner_job.rb
```
- Solid Queue recurring task: every 5 minutes
- Calls `Hl7::MinioScanner.new.scan_and_import`
- Logs result; warns on errors

#### `Hl7LinkPendingJob`
```
app/jobs/hl7_link_pending_job.rb
```
- Solid Queue recurring task: every 15 minutes
- Calls `Hl7::PendingImportLinker.new.link_pending_imports`
- Logs result; warns on errors

#### `Hl7RetryFailedJob`
```
app/jobs/hl7_retry_failed_job.rb
```
- Solid Queue recurring task: every 30 minutes
- Iterates `Hl7Import.ready_for_retry.find_each`
- Sets `status: :retry_scheduled`, increments `retry_count`, updates `last_retry_at`
- Enqueues `Hl7::MeasurementImportJob` for each

### Namespaced (enqueued dynamically)

#### `Hl7::MeasurementImportJob`
```
app/jobs/hl7/measurement_import_job.rb
```
- Receives `hl7_import_id`; finds `Hl7Import` record
- Calls `Hl7::MeasurementImporter.new(hl7_import).import`
- Does NOT use `retry_on` — the importer handles its own error marking; job-level retries would double-count `retry_count`

### Solid Queue Configuration

`config/solid_queue.yml` recurring tasks section:
```yaml
recurring_tasks:
  hl7_minio_scanner:
    class: Hl7MinioScannerJob
    schedule: every 5 minutes
    queue: background
  hl7_link_pending:
    class: Hl7LinkPendingJob
    schedule: every 15 minutes
    queue: background
  hl7_retry_failed:
    class: Hl7RetryFailedJob
    schedule: every 30 minutes
    queue: background
```

## Entity Relationships

```
Measurement (Id)
  └── has_one :hl7_import (measurement_id → Measurements.Id)
  └── has_one :result (MeasurementId)
        └── has_many :analyte_results (ResultId)
              └── belongs_to :analyte (AnalyteId → Analytes.Id)

Hl7Import
  └── belongs_to :measurement (optional)
  └── has_one_attached :hl7_file (ActiveStorage)
```

## HL7 OBX Identifier → DB Analyte Mapping Table

### Project 32 — NutriPATH Urine Metals (`UCR,usEssEl,UsMetox`)

| HL7 OBX-3 Code | HL7 Description       | HL7 Unit | DB NameInAPI      | DB Unit     | Conversion      |
|----------------|-----------------------|----------|-------------------|-------------|-----------------|
| UCR / CrSpUr   | Creatinine            | mmol/L   | krea              | mg/dl       | mmol/L → mg/dl (× 113.12 / 10) |
| 42220-4        | Chromium (Cr)         | ug/gCR   | chromium          | µg/l        | ug/gCR → µg/L   |
| 42220-4        | Chromium (Cr)         | ug/gCR   | chromium_crea     | µg/g crea   | direct          |
| 34270-9        | Cobalt (Co)           | ug/gCR   | cobalt            | µg/l        | ug/gCR → µg/L   |
| 34270-9        | Cobalt (Co)           | ug/gCR   | cobalt_crea       | µg/g crea   | direct          |
| 13829-7        | Copper (Cu)           | ug/gCR   | copper            | µg/l        | ug/gCR → µg/L   |
| 13829-7        | Copper (Cu)           | ug/gCR   | copper_crea       | µg/g crea   | direct          |
| 13465-0        | Mercury (Hg)          | ug/gCR   | mercury           | µg/l        | ug/gCR → µg/L   |
| 13465-0        | Mercury (Hg)          | ug/gCR   | mercury_crea      | µg/g crea   | direct          |
| 13466-8        | Lead (Pb)             | ug/gCR   | lead              | µg/l        | ug/gCR → µg/L   |
| 13466-8        | Lead (Pb)             | ug/gCR   | lead_crea         | µg/g crea   | direct          |
| 13470-0        | Aluminum (Al)         | ug/gCR   | aluminium         | µg/l        | ug/gCR → µg/L   |
| 13470-0        | Aluminum (Al)         | ug/gCR   | aluminium_crea    | µg/g crea   | direct          |
| 13463-5        | Arsenic-total (As)    | ug/gCR   | arsenic           | µg/l        | ug/gCR → µg/L   |
| 13463-5        | Arsenic-total (As)    | ug/gCR   | arsenic_crea      | µg/g crea   | direct          |
| 56651-3        | Cadmium (Cd)          | ug/gCR   | cadmium           | µg/l        | ug/gCR → µg/L   |
| 56651-3        | Cadmium (Cd)          | ug/gCR   | cadmium_crea      | µg/g crea   | direct          |
| 13472-6        | Nickel (Ni)           | ug/gCR   | nickel            | µg/L        | ug/gCR → µg/L   |
| 13472-6        | Nickel (Ni)           | ug/gCR   | nickel_crea       | µg/g crea   | direct          |
| 13473-4        | Zinc (Zn)             | mg/gCR   | zinc              | µg/l        | mg/gCR → µg/L (×1000) |
| 13473-4        | Zinc (Zn)             | mg/gCR   | zinc_crea         | µg/g crea   | direct (as mg/g crea) |

**Ignored analytes** (present in HL7, not in Project 32 DB): Iron (27411-8), Manganese (27367-2), Molybdenum (73583-7), Selenium (13467-6), Vanadium (13831-3), Calcium (9321-1), Magnesium (13474-2), Germanium (5655-6), Lithium (34331-9), Strontium (17658-6), Antimony (13823-0), Barium (13826-3), Beryllium (13827-1), Bismuth (16469-9), Platinum (52925-5), Silver (13476-7), Thallium (13469-2), Tin (17710-5).

### Project 29 — NutriPATH Urine Iodine (`UR-IODINE,uIodEx,UIodCom,usCr`)

| HL7 OBX-3 Code | HL7 Description            | HL7 Unit | DB NameInAPI   | DB Unit          | Conversion                        |
|----------------|----------------------------|----------|----------------|------------------|-----------------------------------|
| usCr           | Creatinine, Urine Spot     | mmol/L   | kreatinin_iu   | mg/dl            | mmol/L → mg/dl (× 113.12 / 10)   |
| uIodEx         | Urine Iodine Corrected     | ug/gCR   | jod_krea_iu    | ug/g creatinine  | direct (ug/gCR stored as-is)      |
| UR-IODINE      | URINE IODINE               | ug/L     | iodine_ng_ml   | ng/ml            | 1 ug/L = 1 ng/ml (factor 1:1)    |

**Ignored analytes** (present in HL7, not in Project 29 DB): UIodCom (FT type — formatted text comment, always skipped).

## Migration Compatibility Note

The `Measurements` table uses `Id` as PK (not `id`). The FK declaration must reference `primary_key: "Id"`. The `add_foreign_key` call uses the table name `"Measurements"` (capitalized, matching Rails table config).
