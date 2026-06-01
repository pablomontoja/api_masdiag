# Implementation Plan: HL7 MinIO Import

**Branch**: `001-hl7-minio-import` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-hl7-minio-import/spec.md`

## Summary

Implement a background scanning and import pipeline that reads HL7 result files from a dedicated MinIO S3 bucket, parses them using the ruby-hl7 gem, and persists analyte results into the database linked to `Measurement` records. The pipeline handles the out-of-order case (file arrives before kit registration) via an `awaiting_registration` status and a re-linkage job.

## Technical Context

**Language/Version**: Ruby 3.1.2 / Rails 7 (API-only)

**Primary Dependencies**: aws-sdk-s3 (already present), ruby-hl7 (to be added), ActiveStorage (already configured with MinIO), Solid Queue (background jobs)

**Storage**: MySQL — existing `Measurements`, `Results`, `AnalyteResults`, `Analytes` tables (capitalized, integer PKs). New `hl7_imports` table (integer PK).

**Testing**: RSpec with FactoryBot. Request specs use `http_auth_header`. Service and job specs are unit tests.

**Target Platform**: Linux server (production), same as existing app

**Project Type**: API-only Rails service (internal background processing — no HTTP endpoints needed for this feature)

**Performance Goals**: Process each HL7 file in under 5 seconds. Scanner should handle buckets with hundreds of files.

**Constraints**: Integer PKs throughout (no UUIDs). `measurement_id` nullable during awaiting-registration phase. Existing `Note` model is out of scope (restricted key list). No new controller or HTTP endpoint needed.

**Scale/Scope**: Low volume — tens to hundreds of HL7 files per day per lab partner.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Rails Conventions | ✅ PASS | Standard model/service/job structure, no deviations |
| II. Service-Object Architecture | ✅ PASS | `Hl7::MinioScanner` and `Hl7::MeasurementImporter` are service objects; jobs are thin async triggers |
| III. Test-First | ✅ PASS | RSpec specs required before implementation code; factories only |
| IV. Security & Secrets | ✅ PASS | MinIO credentials via `Rails.application.credentials.dig(:hl7_s3, ...)` — never hardcoded |
| V. Multi-Tenancy Integrity | ✅ PASS | No cross-tenant data access; imports are scoped to specific measurements |
| VI. Layered Architecture | ✅ PASS | Scanner/Importer in `app/services/hl7/`; jobs in `app/jobs/hl7/`; config constants in `app/lib/hl7/`; model in `app/models/` |

**Re-check after design**: All gates still pass. No new directories required — `hl7/` subdirectories fit within existing canonical structure.

## Project Structure

### Documentation (this feature)

```text
specs/001-hl7-minio-import/
├── plan.md           ← this file
├── spec.md           ← feature specification
├── research.md       ← Phase 0 decisions
├── data-model.md     ← Phase 1 entities and schema
└── tasks.md          ← Phase 2 output (via /speckit-tasks)
```

### Source Code (repository root)

```text
app/
├── models/
│   └── hl7_import.rb                          # new model
├── services/
│   └── hl7/
│       ├── minio_scanner.rb                   # new service
│       ├── measurement_importer.rb            # new service
│       └── pending_import_linker.rb           # new service
├── jobs/
│   ├── hl7_minio_scanner_job.rb               # new job (Solid Queue recurring, every 5 min)
│   ├── hl7_link_pending_job.rb                # new job (Solid Queue recurring, every 15 min)
│   ├── hl7_retry_failed_job.rb                # new job (Solid Queue recurring, every 30 min)
│   └── hl7/
│       └── measurement_import_job.rb          # new job (enqueued dynamically)
└── lib/
    └── hl7/
        └── config.rb                          # new constants

db/
└── migrate/
    └── YYYYMMDDHHMMSS_create_hl7_imports.rb   # new migration

spec/
├── models/
│   └── hl7_import_spec.rb
├── services/
│   └── hl7/
│       ├── minio_scanner_spec.rb
│       ├── measurement_importer_spec.rb
│       └── pending_import_linker_spec.rb
└── jobs/
    ├── hl7_minio_scanner_job_spec.rb
    ├── hl7_link_pending_job_spec.rb
    ├── hl7_retry_failed_job_spec.rb
    └── hl7/
        └── measurement_import_job_spec.rb

Gemfile                                        # add ruby-hl7 gem
config/solid_queue.yml                         # add 3 recurring tasks
```

**Structure Decision**: Single-project Rails layout. All new files go under existing `app/` canonical directories with `hl7/` subdirectory grouping. No new top-level directories.

## Known Blockers

| Blocker | Resolution |
|---------|------------|
| `Hl7::Config::SYSTEM_USER_ID` is `nil` | Must be set to the integer ID of the system/automated user before the first import. Use hardcoded `User.find(24)` like in `Cerascreen::Labordatenbank::ResultImporterJob` if not specified. |

## Complexity Tracking

> No Constitution violations requiring justification.

## Analyte Mapping Summary

### Project 32 — NutriPATH Urine Metals (`UCR,usEssEl,UsMetox`)

Each metal OBX segment produces **two** DB rows: one absolute (µg/L) and one creatinine-normalized (µg/g crea).

**Creatinine conversion** (required before processing metal analytes):
```
creatinine_g_per_L = creatinine_mmol_L × 113.12 / 1000
µg/L = ug_per_gCR × creatinine_g_per_L          # for ug/gCR analytes
µg/L = mg_per_gCR × 1000 × creatinine_g_per_L   # for mg/gCR analytes (Zinc)
```

| HL7 Code     | Element    | HL7 Unit | DB NameInAPI (raw) | DB NameInAPI (crea) |
|--------------|------------|----------|--------------------|---------------------|
| UCR / CrSpUr | Creatinine | mmol/L   | krea (mg/dl)       | —                   |
| 42220-4      | Chromium   | ug/gCR   | chromium           | chromium_crea       |
| 34270-9      | Cobalt     | ug/gCR   | cobalt             | cobalt_crea         |
| 13829-7      | Copper     | ug/gCR   | copper             | copper_crea         |
| 13465-0      | Mercury    | ug/gCR   | mercury            | mercury_crea        |
| 13466-8      | Lead       | ug/gCR   | lead               | lead_crea           |
| 13470-0      | Aluminum   | ug/gCR   | aluminium          | aluminium_crea      |
| 13463-5      | Arsenic    | ug/gCR   | arsenic            | arsenic_crea        |
| 56651-3      | Cadmium    | ug/gCR   | cadmium            | cadmium_crea        |
| 13472-6      | Nickel     | ug/gCR   | nickel             | nickel_crea         |
| 13473-4      | Zinc       | mg/gCR   | zinc               | zinc_crea           |

18 other analytes in HL7 (Iron, Manganese, Molybdenum, Selenium, Vanadium, Calcium, Magnesium, Germanium, Lithium, Strontium, Antimony, Barium, Beryllium, Bismuth, Platinum, Silver, Thallium, Tin) are silently skipped — not in Project 32.

### Project 29 — NutriPATH Urine Iodine (`UR-IODINE,uIodEx,UIodCom,usCr`)

Simpler panel — 3 NM segments, no dual-row processing.

| HL7 Code   | Element             | HL7 Unit | DB NameInAPI   | DB Unit          | Conversion                     |
|------------|---------------------|----------|----------------|------------------|--------------------------------|
| usCr       | Creatinine          | mmol/L   | kreatinin_iu   | mg/dl            | mmol/L → mg/dl (× 113.12 / 10) |
| uIodEx     | Iodine (normalized) | ug/gCR   | jod_krea_iu    | ug/g creatinine  | direct (ug/gCR stored as-is)   |
| UR-IODINE  | Iodine (absolute)   | ug/L     | iodine_ng_ml   | ng/ml            | 1 ug/L = 1 ng/ml (factor 1:1) |

The `UIodCom` segment is `FT` (formatted text) — always skipped.

## Implementation Sequence

### Step 1: Gemfile + Migration

1. Add `gem "ruby-hl7"` to Gemfile
2. Create migration `create_hl7_imports` (see `data-model.md` for schema)
3. Run `bundle install` and `bin/rails db:migrate` (dev + test)

### Step 2: Model + Config

1. Create `Hl7Import` model with enum (including `retry_scheduled: 6`), `ready_for_retry` scope, associations, and state-transition methods
2. Add `has_one :hl7_import` to `Measurement` model
3. Create `app/lib/hl7/config.rb` with complete `TEST_MAPPING`, `ANALYTE_MAPPING`, `ARCHIVE_FOLDER`, `SYSTEM_USER_ID`, `CREATININE_MOLAR_MASS`, `UG_PER_L_DIRECT_IDENTIFIERS`
4. Create `spec/models/hl7_import_spec.rb`

### Step 3: Scanner Service + Scheduled Job

1. Create `Hl7::MinioScanner` service (scan → parse metadata → create import → link or mark awaiting)
2. Create `Hl7MinioScannerJob` (flat class for Solid Queue recurring, calls `Hl7::MinioScanner`)
3. Specs: `minio_scanner_spec.rb`, `hl7_minio_scanner_job_spec.rb`

### Step 4: Importer Service + Job

1. Create `Hl7::MeasurementImporter` service (download → parse HL7 → create Result → bulk-insert AnalyteResults → update Measurement → archive)
2. Create `Hl7::MeasurementImportJob` (dynamically enqueued, calls importer)
3. Specs: `measurement_importer_spec.rb`, `measurement_import_job_spec.rb`

### Step 5: Pending Import Linker + Retry Jobs

1. Create `Hl7::PendingImportLinker` service (find_each over awaiting_registration → Sample lookup → Measurement match → link + enqueue)
2. Create `Hl7LinkPendingJob` (flat class for Solid Queue recurring, calls linker)
3. Create `Hl7RetryFailedJob` (flat class for Solid Queue recurring, re-enqueues failed imports via `ready_for_retry` scope)
4. Specs: `pending_import_linker_spec.rb`, `hl7_link_pending_job_spec.rb`, `hl7_retry_failed_job_spec.rb`

### Step 6: Solid Queue Configuration

1. Add recurring tasks to `config/solid_queue.yml`: `hl7_minio_scanner` (5 min), `hl7_link_pending` (15 min), `hl7_retry_failed` (30 min)

### Step 7: Integration Verification

1. Run full RSpec suite: `bundle exec rspec`
2. Manual smoke test in development with a real HL7 file

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| FK reference | `measurement_id` (nullable integer) | Supports awaiting_registration; matches app integer PK convention |
| Status storage | Integer enum | Consistent with `Measurement.Status` pattern in this app |
| HL7 parsing | ruby-hl7 gem | Per spec requirement |
| Credential namespace | `:hl7_s3` | Separate from `:minio` (ActiveStorage) to allow different bucket/endpoint |
| File attachment | ActiveStorage | Audit trail and reprocessing capability |
| Archive mechanism | Direct aws-sdk-s3 copy+delete | Matches source app pattern; ActiveStorage doesn't support cross-prefix moves |
| Notifications | None | `notes` key list would require constitution amendment |
| Import user | `Hl7::Config::SYSTEM_USER_ID` | Same pattern as Cerascreen importer |
| Unit conversion | ug/gCR × creatinine_g_per_L | DB stores µg/L absolute; HL7 provides normalized values; creatinine back-converts them |
| Dual-row processing | One OBX → two DB rows | Each metal: one raw (µg/L) + one crea-normalized (µg/g crea) via `_crea` key suffix |
| mg/gCR handling | Read OBX-6 unit at runtime | Factor (×1 for ug/gCR, ×1000 for mg/gCR) determined from OBX-6 in the HL7 file — not from a static identifier list in config. Robust to new analytes without config changes. |
| Measurement lookup | `Sample.find_by(Code:)` + `measurements.find_by(ProjectId:)` | No Kit/usable_test in this app; Sample.Code is the barcode from OBR-13/PID-5 |
| Re-linkage pattern | `Hl7::PendingImportLinker` service + `Hl7LinkPendingJob` | Adapted from source app's `PendingImportLinker`; same find_each pattern, different lookup chain |
| Job naming (recurring) | Flat top-level classes (`Hl7MinioScannerJob`, `Hl7LinkPendingJob`, `Hl7RetryFailedJob`) | Solid Queue recurring tasks require class names as strings; nested classes (`Hl7::ScanJob`) cause constant resolution issues in some Rails versions |
| Scheduling | Solid Queue recurring tasks in `config/solid_queue.yml` | Native Solid Queue scheduling — no separate cron or Sidekiq Scheduler needed |
| Retry mechanism | `Hl7RetryFailedJob` + `ready_for_retry` scope (max 3 retries) | Separate retry job decouples retry logic from the importer; `retry_count` tracks attempts; `retry_scheduled` status prevents double-enqueue |
