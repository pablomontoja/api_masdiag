# Tasks: HL7 MinIO Import

**Input**: Design documents from `specs/001-hl7-minio-import/`

**Branch**: `001-hl7-minio-import` | **Date**: 2026-06-01

**Organization**: Tasks grouped by user story — each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Gem and database foundation required by all user stories.

- [X] T001 Add `gem "ruby-hl7"` to `Gemfile` and run `bundle install`
- [X] T002 Create migration `db/migrate/YYYYMMDDHHMMSS_create_hl7_imports.rb` (integer PK, nullable `measurement_id`, `s3_key` unique index, status integer, retry fields, timestamps) and run `bin/rails db:migrate` + `bin/rails db:migrate RAILS_ENV=test`

**Checkpoint**: `bundle exec ruby -e "require 'hl7'" && bin/rails db:migrate:status` passes — foundation ready.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model, config constants, and `Measurement` association that every service and job depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T00X Create `app/models/hl7_import.rb` — `Hl7Import` model with: `belongs_to :measurement` (optional, FK `:measurement_id`, PK `"Id"`), `has_one_attached :hl7_file`, status enum (0–6 including `retry_scheduled: 6`), `mark_completed!`, `mark_failed!`, `mark_awaiting_registration!`, `mark_registration_error!` instance methods, and `ready_for_retry` scope (`where(status: :failed).where("retry_count < 3")`)
- [X] T00X Add `has_one :hl7_import, class_name: "Hl7Import", foreign_key: :measurement_id, primary_key: "Id"` to `app/models/measurement.rb`
- [X] T00X [P] Create `app/lib/hl7/config.rb` — `Hl7::Config` module with `ARCHIVE_FOLDER`, `SYSTEM_USER_ID` (set to `nil` — **BLOCKER**: must be resolved before first real import; check `Cerascreen::Labordatenbank::ResultImporterJob` for the integer value), `CREATININE_MOLAR_MASS = 113.12`, `TEST_MAPPING` (Project 32 and 29 codes → ProjectId), complete `ANALYTE_MAPPING` (all Project 32 metals × 2 variants + Project 29 iodine analytes), `UG_PER_L_DIRECT_IDENTIFIERS = %w[UR-IODINE]`
- [X] T00X [P] Create `spec/models/hl7_import_spec.rb` — unit specs for: enum values, `ready_for_retry` scope (returns failed records with `retry_count < 3`, excludes `retry_count >= 3`), all `mark_*!` transition methods, `has_one_attached :hl7_file`, `belongs_to :measurement` (optional)

**Checkpoint**: `bundle exec rspec spec/models/hl7_import_spec.rb` passes — model and config ready.

---

## Phase 3: User Story 1 — Scan and Ingest New HL7 Files (Priority: P1) 🎯 MVP

**Goal**: Background scanner detects new HL7 files in MinIO, creates `Hl7Import` records, links to `Measurement` or marks awaiting registration.

**Independent Test**: Trigger `Hl7MinioScannerJob.new.perform` with a seeded HL7 file in MinIO (or stub the S3 client); verify `Hl7Import` row is created, `s3_key`/`kit_code_extracted`/`hl7_test_code` are populated, and the record is either linked (`measurement_id` set, status `pending`) or unlinked (status `awaiting_registration`).

### Implementation for User Story 1

- [X] T00X [US1] Create `app/services/hl7/minio_scanner.rb` — `Hl7::MinioScanner` service:
  - Constructor: builds `Aws::S3::Client` from `credentials.dig(:hl7_s3, ...)`, sets `@bucket`
  - `#scan_and_import`: lists bucket objects, filters `archive/` prefix and already-imported `s3_key` values (via `Hl7Import.pluck(:s3_key)`), calls `process_s3_file` for each new object, returns `{ new_files:, errors: }` hash
  - `#process_s3_file`: downloads file, calls `parse_hl7_metadata`, creates `Hl7Import` + attaches file via ActiveStorage, then calls `find_measurement_for_import` → `link_and_process` or `mark_as_awaiting_registration`
  - `#parse_hl7_metadata`: uses `HL7::Message.new(content)`, extracts barcode from OBR-13 (fallback PID-5 component 1), test code from OBR-4 component 1; returns `{ kit_code:, test_code: }`
  - `#find_measurement_for_import`: `Sample.find_by(Code: kit_code)` → `measurements.find_by(ProjectId: project_id)` using `TEST_MAPPING`
  - Rescues `Aws::S3::Errors::ServiceError` at `scan_and_import` level → logs, returns error hash
- [X] T00X [P] [US1] Create `spec/services/hl7/minio_scanner_spec.rb` — unit specs covering:
  - Happy path: new file → `Hl7Import` created with correct attributes, linked to measurement, `Hl7::MeasurementImportJob` enqueued
  - Barcode not found → status `awaiting_registration`, no job enqueued
  - Already-imported `s3_key` → skipped (no duplicate record)
  - MinIO `ServiceError` → returns error hash without raising
  - Stub `Aws::S3::Client` with doubles; use FactoryBot for `Sample` and `Measurement`
- [X] T00X [US1] Create `app/jobs/hl7_minio_scanner_job.rb` — flat `Hl7MinioScannerJob < ApplicationJob`:
  - `queue_as :background`
  - `#perform`: calls `Hl7::MinioScanner.new.scan_and_import`, logs result, warns if `result[:errors].any?`
- [X] T0XX [P] [US1] Create `spec/jobs/hl7_minio_scanner_job_spec.rb` — unit spec: verify job calls `Hl7::MinioScanner#scan_and_import` and logs result

**Checkpoint**: `bundle exec rspec spec/services/hl7/minio_scanner_spec.rb spec/jobs/hl7_minio_scanner_job_spec.rb` — User Story 1 fully testable.

---

## Phase 4: User Story 2 — Parse HL7 and Persist Analyte Results (Priority: P2)

**Goal**: Importer job downloads attached HL7 file, parses segments, converts values, bulk-inserts `AnalyteResult` rows, updates `Measurement.Status = 4`, archives source file.

**Independent Test**: Create a linked `Hl7Import` (status `pending`) with a valid HL7 file attached via ActiveStorage; run `Hl7::MeasurementImportJob.new.perform(hl7_import.id)`; verify `AnalyteResult` rows exist with correct values, `Result` record created (`ImportUserId` set), `Measurement.Status = 4`.

### Implementation for User Story 2

- [X] T0XX [US2] Create `app/services/hl7/measurement_importer.rb` — `Hl7::MeasurementImporter` plain service:
  - Constructor: `initialize(hl7_import)` — stores `@hl7_import`, derives `@measurement`, `@project_id`
  - `#import` (public, returns `true`/`false`): wraps DB work in `ActiveRecord::Base.transaction`
    - Sets `status: :processing`
    - Downloads HL7 via `@hl7_import.hl7_file.download`
    - Parses with `HL7::Message.new(content)`; validates MSH + OBR present; marks `failed!` and returns `false` if missing
    - Updates HL7 metadata fields on the import record
    - Extracts creatinine OBX (identifier in `{ "UCR", "CrSpUr", "usCr" }`): converts `mmol/L → mg/dl` (× 113.12 / 10) for DB, and `mmol/L → g/L` (× 113.12 / 1000) for metal back-conversion; fails if creatinine missing/zero AND project is 32
    - Processes NM-type OBX segments: for each, looks up plain key in `ANALYTE_MAPPING`; if a `CODE_crea` key also exists, processes twice (raw → absolute µg/L via OBX-6 unit; `_crea` → direct store); for `UG_PER_L_DIRECT_IDENTIFIERS` stores value 1:1 (ug/L = ng/ml); unrecognised codes logged as warnings in `processing_stats`
    - Creates or finds `Result` record (`Results` table, PK = `MeasurementId`); sets `ImportUserId: Hl7::Config::SYSTEM_USER_ID`
    - Deletes existing `AnalyteResult` rows for this `ResultId`, bulk-inserts new rows via `AnalyteResult.insert_all`
    - Updates `Measurement.Status = 4, MeasureDate = Time.current`
    - Calls `mark_completed!(stats)` inside transaction
  - Archives file after transaction (copy to `archive/`, delete original via `aws-sdk-s3`); failure does not roll back import
  - On `StandardError`: calls `mark_failed!(message)`, returns `false`
- [X] T0XX [P] [US2] Create `spec/services/hl7/measurement_importer_spec.rb` — unit specs:
  - Project 32 happy path: valid HL7 with creatinine + metals → correct `AnalyteResult` rows (chromium raw + crea), `Measurement.Status = 4`, import `completed`
  - Project 29 happy path: iodine HL7 → `kreatinin_iu` (mg/dl), `jod_krea_iu` (direct), `iodine_ng_ml` (1:1) rows created
  - Zinc mg/gCR: OBX-6 = "mg/gCR" → factor ×1000 applied correctly
  - Missing creatinine on Project 32 → import marked `failed`, exception message includes "creatinine"
  - Missing MSH → import marked `failed`
  - Unknown OBX code → skipped, warning in `processing_stats`, rest of import continues
  - Existing `AnalyteResult` rows replaced (not duplicated)
  - Archive failure (S3 error) → import stays `completed` (not rolled back)
  - Use FactoryBot factories; stub `aws-sdk-s3` for archiving
- [X] T0XX [US2] Create `app/jobs/hl7/measurement_import_job.rb` — `Hl7::MeasurementImportJob < ApplicationJob`:
  - `queue_as :default`
  - `#perform(hl7_import_id)`: finds `Hl7Import`, calls `Hl7::MeasurementImporter.new(hl7_import).import`
  - No `retry_on` — importer handles its own `mark_failed!`; job-level retries would double-count `retry_count`
- [X] T0XX [P] [US2] Create `spec/jobs/hl7/measurement_import_job_spec.rb` — unit spec: verify job finds `Hl7Import` by id and delegates to `Hl7::MeasurementImporter#import`

**Checkpoint**: `bundle exec rspec spec/services/hl7/measurement_importer_spec.rb spec/jobs/hl7/measurement_import_job_spec.rb` — User Story 2 fully testable.

---

## Phase 5: User Story 3 — Retry Awaiting Registrations (Priority: P3)

**Goal**: Re-linkage service and retry job resolve `awaiting_registration` imports once their measurements are registered; failed imports are retried up to 3 times.

**Independent Test**: Create an `Hl7Import` with `awaiting_registration` status and `kit_code_extracted` matching a real `Sample`; run `Hl7LinkPendingJob.new.perform`; verify import is now linked (`measurement_id` set, status `pending`) and `Hl7::MeasurementImportJob` is enqueued. Separately create 2 failed imports (`retry_count < 3`) and 1 exhausted (`retry_count = 3`); run `Hl7RetryFailedJob.new.perform`; verify only the 2 eligible ones are enqueued.

### Implementation for User Story 3

- [X] T0XX [US3] Create `app/services/hl7/pending_import_linker.rb` — `Hl7::PendingImportLinker` service:
  - `#link_pending_imports`: iterates `Hl7Import.where(status: :awaiting_registration).find_each`
  - For each: resolves `project_id = Hl7::Config::TEST_MAPPING[hl7_import.hl7_test_code]`; unknown test code → `mark_registration_error!("Unknown test code")`, next
  - `sample = Sample.find_by(Code: hl7_import.kit_code_extracted)`; `measurement = sample&.measurements&.find_by(ProjectId: project_id)`
  - On match: `hl7_import.update!(measurement_id: measurement.id, status: :pending)`; enqueues `Hl7::MeasurementImportJob`
  - No match: increments `still_waiting` counter, leaves status unchanged
  - Returns `{ linked:, waiting:, errors: }` summary hash
- [X] T0XX [P] [US3] Create `spec/services/hl7/pending_import_linker_spec.rb` — unit specs:
  - Match found → import linked, job enqueued
  - No matching sample → import unchanged, counted in `waiting`
  - Unknown test code → import marked `registration_error`
  - Multiple awaiting imports — each processed independently
- [X] T0XX [US3] Create `app/jobs/hl7_link_pending_job.rb` — flat `Hl7LinkPendingJob < ApplicationJob`:
  - `queue_as :background`
  - `#perform`: calls `Hl7::PendingImportLinker.new.link_pending_imports`, logs result
- [X] T0XX [US3] Create `app/jobs/hl7_retry_failed_job.rb` — flat `Hl7RetryFailedJob < ApplicationJob`:
  - `queue_as :background`
  - `#perform`: iterates `Hl7Import.ready_for_retry.find_each`; for each: sets `status: :retry_scheduled`, increments `retry_count`, sets `last_retry_at: Time.current`; enqueues `Hl7::MeasurementImportJob`
- [X] T0XX [P] [US3] Create `spec/jobs/hl7_link_pending_job_spec.rb` — unit spec: job delegates to `Hl7::PendingImportLinker#link_pending_imports`
- [X] T0XX [P] [US3] Create `spec/jobs/hl7_retry_failed_job_spec.rb` — unit specs: eligible failed imports are set to `retry_scheduled` and enqueued; exhausted (`retry_count >= 3`) are skipped

**Checkpoint**: `bundle exec rspec spec/services/hl7/pending_import_linker_spec.rb spec/jobs/hl7_link_pending_job_spec.rb spec/jobs/hl7_retry_failed_job_spec.rb` — User Story 3 fully testable.

---

## Phase 6: Solid Queue Configuration & Integration Verification

**Purpose**: Wire recurring tasks into Solid Queue and run full suite.

- [X] T0XX Add three recurring tasks to `config/solid_queue.yml`:
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
- [X] T0XX Resolve `Hl7::Config::SYSTEM_USER_ID` — find the integer ID of the system user (check `Cerascreen::Labordatenbank::ResultImporterJob` or run `User.find(24)` in Rails console) and set it in `app/lib/hl7/config.rb`; **BLOCKER**: import will fail with nil `ImportUserId` until this is done
- [X] T0XX Run full RSpec suite: `bundle exec rspec` — all new specs pass, no existing regressions
- [X] T0XX Manual smoke test in development: place a real NutriPATH HL7 file in the MinIO HL7 bucket, run `Hl7MinioScannerJob.new.perform` from Rails console, verify `Hl7Import` created; then run `Hl7::MeasurementImportJob.new.perform(hl7_import.id)`, verify `AnalyteResult` rows and `Measurement.Status = 4`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 completion
- **Phase 4 (US2)**: Depends on Phase 2 completion; can start in parallel with Phase 3
- **Phase 5 (US3)**: Depends on Phase 2 completion; depends on Phase 3 services (uses `Hl7::MeasurementImportJob`) and Phase 4 (linker enqueues import job)
- **Phase 6 (Integration)**: Depends on all Phases 3–5 complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational — independent
- **US2 (P2)**: Depends only on Foundational — can run in parallel with US1
- **US3 (P3)**: Depends on US1 (scanner creates awaiting_registration records) and US2 (linker enqueues import job); implement after US1 and US2

### Within Each User Story

- Service implementation before job implementation
- Spec tasks (marked [P]) can run in parallel with implementation tasks when working in different files

### Parallel Opportunities

```bash
# Phase 2 — can run in parallel:
T003  # Hl7Import model
T005  # Hl7::Config constants

# Phase 3 — sequential (service before job):
T007 → T009

# Phase 4 — sequential:
T011 → T013

# Phase 5 — sequential:
T015 → T017 (linker service before link job)
T015 → T018 (linker before retry job; both need MeasurementImportJob from US2)

# Specs in each phase — parallel with implementation:
T008 ∥ T007   # minio_scanner_spec ∥ minio_scanner
T010 ∥ T009   # scanner_job_spec ∥ scanner_job
T012 ∥ T011   # importer_spec ∥ importer
T014 ∥ T013   # import_job_spec ∥ import_job
T016 ∥ T015   # linker_spec ∥ linker
T019 ∥ T017   # link_job_spec ∥ link_job
T020 ∥ T018   # retry_job_spec ∥ retry_job
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T006)
3. Complete Phase 3: User Story 1 (T007–T010)
4. **STOP and VALIDATE**: `bundle exec rspec spec/models/hl7_import_spec.rb spec/services/hl7/minio_scanner_spec.rb spec/jobs/hl7_minio_scanner_job_spec.rb`
5. Manual smoke test: scanner creates `Hl7Import` records from MinIO

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → scanner creates and links records (or marks awaiting)
3. US2 → importer processes linked records, AnalyteResults persisted
4. US3 → re-linkage + retry loops operational
5. Phase 6 → Solid Queue wired, system fully automated

---

## Notes

- [P] tasks = different files, no shared dependencies — safe to run in parallel
- [Story] label maps task to user story for traceability
- `SYSTEM_USER_ID` (T022) is a **BLOCKER** — the importer will fail on `Result.ImportUserId = nil` until resolved
- `measurement_id` nullable unique index: MySQL allows multiple NULLs — awaiting_registration records coexist safely; once linked, uniqueness prevents duplicate imports per measurement
- Retry lifecycle: `failed → retry_scheduled → (re-enqueued) → processing → failed` (max 3 cycles); `ready_for_retry` scope stops returning records once `retry_count = 3`
- `MeasurementImportJob` has no `retry_on` by design — the importer manages its own `mark_failed!`; job-level retries would double-count `retry_count`
- Creatinine requires two derivations from the same mmol/L value: `× 113.12 / 10` for mg/dl DB storage, `× 113.12 / 1000` for metal back-conversion
- mg/gCR vs ug/gCR factor is determined from OBX-6 at runtime — not from a static list in config
