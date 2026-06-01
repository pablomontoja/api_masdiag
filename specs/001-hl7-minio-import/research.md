# Research: HL7 MinIO Import

## Domain Model Findings

### Measurement → Result → AnalyteResult Chain

**Decision**: `Hl7Import` links to `Measurement` via `measurement_id` (integer FK). The import flow must also create a `Result` record (PK = `MeasurementId`) before inserting `AnalyteResult` rows.

**Rationale**: In this application, `Result` is a required intermediary — `AnalyteResult.ResultId` is a FK to `Results.MeasurementId`. The source app's `result_id` maps to this `Measurement.Id` context.

**Key schema facts**:
- `Measurements` table uses `Id` (integer PK), `Status` (integer), `MeasureDate` (datetime), `ProjectId` (integer)
- `Results` table PK = `MeasurementId` (matches `Measurement.Id`); has `ImportDate`, `IsValid`, `ImportUserId`, `PlateCode`
- `AnalyteResults` uses composite PK (`ResultId`, `AnalyteId`); fields `Value` (decimal 20,4), `MeasuredValue` (decimal 18,5), `Unit`
- `Analytes` identified by `NameInAPI` scoped to `ProjectId` and `material_type`

### Measurement Status Workflow

**Decision**: After successful HL7 import, set `Measurement.Status = 4`.

**Rationale**: Examining `Cerascreen::Labordatenbank::ResultImporterJob`, it sets `Status: 4` and `MeasureDate: Time.now` after importing analyte results. Status 4 represents "results entered/measured" in the workflow. Status 1 = registered/created, Status 2 = assigned to plate, Status 4 = results imported.

### Analyte Lookup Strategy

**Decision**: Look up `Analyte` by `NameInAPI` scoped to `ProjectId`. The HL7 test code determines the `ProjectId` via a `Hl7::Config::TEST_MAPPING` hash.

**Rationale**: `Analyte` validates `NameInAPI` uniqueness scoped to `[ProjectId, material_type]`. The importer must know which project's analytes to search. Project IDs are stable integers in this system.

### MinIO S3 Credentials

**Decision**: Use `Rails.application.credentials.dig(:hl7_s3, :access_key_id)` etc., with a dedicated `hl7_s3` credential namespace.

**Rationale**: The existing MinIO storage (`:minio`) is the ActiveStorage service. The HL7 source bucket is a separate lab-results bucket that should use its own credential namespace to avoid confusion. The `aws-sdk-s3` gem is already in the Gemfile.

**Alternatives considered**: Reusing `:minio` credentials — rejected because the HL7 bucket may differ from the ActiveStorage bucket in endpoint or region.

### ActiveStorage vs Direct S3 for File Attachment

**Decision**: Attach the HL7 file to `Hl7Import` via ActiveStorage (`has_one_attached :hl7_file`) for audit purposes. The file is downloaded from the direct S3 client during processing (not ActiveStorage download) to avoid double-storage complexity during scanning.

**Rationale**: ActiveStorage attachment gives the file a permanent home for reprocessing/audit. The scanner creates the attachment from the already-downloaded content. This matches the source app pattern exactly.

### Note / Notification Approach

**Decision**: No `Note` records for HL7 notifications. No email triggers in this feature.

**Rationale**: The `Note` model has a restricted `available_keys` allowlist that does not include an HL7 key. Adding it would require amending the constitution. Email notification is out of scope per spec assumptions.

### Re-linkage Mechanism

**Decision**: Implement `Hl7::RelinkAwaitingJob` — a background job that scans `awaiting_registration` imports and attempts to match them to measurements.

**Rationale**: This is a separate concern from the main scanner. It should run after sample registrations or on a periodic schedule. The job queries `Hl7Import.where(status: :awaiting_registration)` and calls the same lookup logic used by the scanner.

### Ruby HL7 Gem API

**Decision**: Use `HL7::Message.new(content)` (not `.parse`). Access segments via `msg[:MSH]`, `msg[:OBR]`, `msg[:OBX]` as arrays when multiple segments exist.

**Rationale**: The `ruby-hl7` gem API uses `HL7::Message.new` for string content. Segment access returns segment objects where fields are accessed by index (`seg.e3` or `seg[3]`). When multiple OBX segments exist, `msg.select { |s| s.is_a?(HL7::Message::Segment::OBX) }` retrieves all. The gem must be added to the Gemfile.

**Alternatives considered**: `simple_hl7_parser` gem — rejected per spec requirement to use ruby-hl7.

### Migration Design

**Decision**: `hl7_imports` table uses integer PK (not UUID) to stay consistent with this app's integer-primary-key convention. `measurement_id` is nullable (allows storing imports before measurement is found).

**Rationale**: This app uses integer PKs throughout (no UUID tables). Making `measurement_id` nullable supports the `awaiting_registration` flow where no measurement exists at scan time. The unique index on `s3_key` enforces idempotency.

**Alternatives considered**: UUID PK (source app) — rejected because this app has no UUID pattern.

### Service Object vs Job for Import Logic

**Decision**: Scanner logic lives in `Hl7::MinioScanner` service object (called from `Hl7::ScanJob`). Import logic lives in `Hl7::MeasurementImporter` service object (called from `Hl7::MeasurementImportJob`).

**Rationale**: Constitution Principle II — complex business logic MUST live in `app/services/`. Jobs are async triggers. The `Hl7` module namespace is used for all related files. Service objects return `ApplicationService` result objects.

### Import User for Result Records

**Decision**: The `Result` record requires `ImportUserId`. Use a dedicated system user ID stored in `Hl7::Config::SYSTEM_USER_ID`.

**Rationale**: Looking at `Cerascreen::Labordatenbank::ResultImporterJob`, it hard-codes `User.find(24)`. For HL7 imports, the same pattern is used but the ID is extracted to a config constant.

### HL7 File Structure (NutriPATH urine metals panel)

**Decision**: Extract barcode from OBR-13 first; fall back to PID-5 component 1. Extract test code from OBR-4 component 1 (before first `^`).

**Key observations from sample file**:
- OBR-4: `UCR,usEssEl,UsMetox^UCR,usEssEl,UsMetox^0001` → first component is `UCR,usEssEl,UsMetox` → maps to ProjectId 32
- OBR-13: `A6Y1IF` → sample barcode (`Sample.Code` in DB)
- PID-5 component 1: also `A6Y1IF` — used as fallback if OBR-13 is blank
- OBX segments: each has OBX-3 format `CODE^Description^System^AltCode^AltDesc^AltSystem`; identifier = first component
- OBX-2 value type: `NM` = numeric result (process), `FT` = formatted text (skip/comment)
- OBX-6 units field: `ug/gCR` or `mg/gCR` — determines conversion factor

### Measurement Lookup Chain (this application)

**Decision**: Find `Measurement` using `Sample.Code` + `ProjectId`.

```ruby
sample = Sample.find_by(Code: sample_code)           # by barcode
project_id = Hl7::Config::TEST_MAPPING[test_code]    # from OBR-4
measurement = sample&.measurements&.find_by(ProjectId: project_id)
```

**Rationale**: In this application, `Sample has_many :measurements`, and each measurement belongs to a `Project`. There is no `Kit`/`usable_test`/`result` chain as in the source (NutriPATH) app. The correct measurement is the one for the right project and sample. If multiple measurements exist for the same project (e.g. repeat measurements), the scanner links to the most recent non-completed one.

**Alternatives considered**: Source app's `Kit → usable_test → result` — not applicable; this app has no Kit model.

### Re-linkage Service: `Hl7::PendingImportLinker`

**Decision**: Rename `RelinkAwaitingJob` → uses `Hl7::PendingImportLinker` service (adapting the source app's `PendingImportLinker`). The service uses `find_each` over `awaiting_registration` imports and attempts the `Sample` + `Measurement` lookup.

**Rationale**: The source app's `PendingImportLinker` pattern maps cleanly to this app's lookup chain when replacing `Kit.find_by(code:)` with `Sample.find_by(Code:)` and removing the `usable_test` step. The `find_each` pattern is correct for batched processing.

**Adapted lookup in this app**:
```ruby
sample = Sample.find_by(Code: hl7_import.kit_code_extracted)
project_id = Hl7::Config::TEST_MAPPING[hl7_import.hl7_test_code]
measurement = sample&.measurements&.find_by(ProjectId: project_id)
```

### Analyte Value Conversion (ug/gCR → µg/L)

**Decision**: The importer must extract the creatinine concentration from OBX (code `UCR` or `CrSpUr`, unit `mmol/L`) and use it to convert creatinine-normalized values to absolute µg/L.

**Formula**:
```
creatinine_g_per_L = creatinine_mmol_L × 113.12 / 1000
value_µg_per_L = hl7_value_ug_per_gCR × creatinine_g_per_L

# For mg/gCR units (Zinc):
value_µg_per_L = hl7_value_mg_per_gCR × 1000 × creatinine_g_per_L
```

**Rationale**: The database stores absolute concentrations (µg/L) for the raw analytes and the normalized form (µg/g crea) separately. The HL7 file only provides creatinine-normalized values, so back-conversion is required. Creatinine molar mass = 113.12 g/mol is a physical constant.

**Alternatives considered**: Storing only the normalized values — rejected because the DB schema already has both columns and both are `is_required: true`.

**Implementation constraint**: If creatinine is absent or zero in the HL7 file, the import MUST fail with a clear error — division by zero or incorrect values would corrupt results.

### Dual-Processing of OBX Segments

**Decision**: Each metal OBX segment is processed twice: once to produce the raw µg/L analyte, and once to produce the `_crea` normalized variant (stored directly in ug/gCR).

**Rationale**: The `ANALYTE_MAPPING` uses a `"CODE_crea"` key convention to distinguish the two DB targets for a single HL7 code. The importer iterates the mapping and checks both `hl7_code` and `hl7_code + "_crea"` keys for each OBX segment.

### Test Code → Project Mapping

**Decision**: `Hl7::Config::TEST_MAPPING = { "UCR,usEssEl,UsMetox" => 32 }`.

**Rationale**: The OBR-4 first component in the sample file is `UCR,usEssEl,UsMetox`, and Project 32 contains all the corresponding analytes. This mapping is a static configuration — new test types require a new entry here plus corresponding analyte entries in `ANALYTE_MAPPING`.
