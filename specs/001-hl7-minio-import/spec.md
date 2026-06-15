# Feature Specification: HL7 MinIO Import

**Feature Branch**: `001-hl7-minio-import`

**Created**: 2026-06-01

**Status**: Draft

**Input**: Import HL7 result files from a dedicated MinIO S3 bucket, parse them using the ruby-hl7 gem, and persist analyte results into the database linked to Measurements.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scan and ingest new HL7 files (Priority: P1)

A background job periodically scans a dedicated MinIO bucket for new HL7 files. For each new file not yet imported, it parses the HL7 content, extracts the sample barcode and test code, creates an `Hl7Import` record, and either links it to an existing `Measurement` or marks it as awaiting registration.

**Why this priority**: This is the core flow — without it nothing else works. All other stories depend on records created here.

**Independent Test**: Trigger the scanner job manually with a seeded HL7 file in MinIO; verify `Hl7Import` row is created and either linked to a `Measurement` or marked `awaiting_registration`.

**Acceptance Scenarios**:

1. **Given** a new HL7 file exists in the MinIO bucket that has not been imported before, **When** the scanner job runs, **Then** an `Hl7Import` record is created with `s3_key`, extracted barcode, and extracted test code.
2. **Given** an HL7 file whose barcode matches a registered `Sample` with a corresponding `Measurement`, **When** the scanner processes it, **Then** the `Hl7Import` is linked to the `Measurement` and enqueued for analyte processing.
3. **Given** an HL7 file whose barcode does not match any registered sample, **When** the scanner processes it, **Then** the `Hl7Import` status is set to `awaiting_registration` and no processing job is enqueued.
4. **Given** an HL7 file that was already imported (same `s3_key`), **When** the scanner runs again, **Then** the file is skipped and no duplicate record is created.
5. **Given** a MinIO connection error, **When** the scanner runs, **Then** the error is logged and a structured error summary is returned without crashing.

---

### User Story 2 - Parse HL7 and persist analyte results (Priority: P2)

Once an `Hl7Import` is linked to a `Measurement`, a background job downloads the HL7 file, parses MSH/OBR/OBX segments, maps analyte identifiers to database `Analyte` records via `NameInAPI`, bulk-inserts `AnalyteResult` rows, updates `Measurement.Status` to the completed stage, and archives the source file.

**Why this priority**: Persisting analyte results is the business value. Without it, imported records are inert.

**Independent Test**: Create a linked `Hl7Import` with a valid HL7 file attached; run `Hl7::MeasurementImportJob`; verify `AnalyteResult` rows are created and `Measurement.Status` is updated.

**Acceptance Scenarios**:

1. **Given** an `Hl7Import` in `pending` status linked to a `Measurement`, **When** the importer job runs, **Then** one `AnalyteResult` row per mapped OBX segment is created with correct `Value` and `AnalyteId`.
2. **Given** an OBX segment whose identifier has no analyte mapping, **When** the importer runs, **Then** the segment is skipped, a warning is recorded in `processing_stats`, and the rest of the import continues.
3. **Given** a malformed HL7 file missing MSH or OBR segments, **When** the importer runs, **Then** the `Hl7Import` is marked `failed` with a descriptive error message.
4. **Given** a successful import, **When** processing completes, **Then** the original file is moved to an archive folder in MinIO and `Hl7Import.status` is set to `completed`.
5. **Given** a `Measurement` that already has `AnalyteResult` rows, **When** the importer runs, **Then** existing rows are replaced with the newly imported values.

---

### User Story 3 - Retry awaiting registrations (Priority: P3)

When a sample is registered after its HL7 file has already arrived, the system can retroactively link `awaiting_registration` imports to the newly created `Measurement` and re-enqueue them for processing.

**Why this priority**: Handles the out-of-order arrival case where the lab result arrives before the patient's kit is registered.

**Independent Test**: Create an `Hl7Import` with `awaiting_registration` status; register the corresponding sample; trigger the re-linkage mechanism; verify the import is now linked and processing is enqueued.

**Acceptance Scenarios**:

1. **Given** an `Hl7Import` in `awaiting_registration` status and a `Measurement` that has since been created, **When** the re-linkage job runs, **Then** the import is linked to the measurement and enqueued for processing.
2. **Given** an import still in `awaiting_registration` with no matching measurement, **When** re-linkage runs, **Then** the import remains unchanged.

---

### Edge Cases

- What happens when the HL7 file contains duplicate OBX identifiers for the same analyte?
- How does the system handle an HL7 file whose barcode maps to multiple measurements (repeat measurements)?
- What if MinIO archiving fails after a successful import — does the import roll back?
- What if the same HL7 file arrives twice with a different `s3_key` (renamed file)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST scan a dedicated MinIO bucket and detect HL7 files not yet recorded in `hl7_imports`.
- **FR-002**: System MUST parse HL7 content using the ruby-hl7 gem, extracting barcode from OBR-13 (fallback PID-5) and test code from OBR-4.
- **FR-003**: System MUST create an `Hl7Import` record for every new file regardless of whether a matching `Measurement` exists.
- **FR-004**: System MUST attach the raw HL7 file to `Hl7Import` via ActiveStorage for audit and reprocessing.
- **FR-005**: System MUST link `Hl7Import` to a `Measurement` using `measurement_id` (not `result_id`).
- **FR-006**: System MUST map HL7 analyte identifiers to database `Analyte` records via `NameInAPI` (column `AnalyteId`) scoped to the correct `ProjectId`.
- **FR-007**: System MUST bulk-insert `AnalyteResult` rows replacing any existing rows for the same `Measurement`.
- **FR-008**: System MUST update `Measurement.Status` after successful import to reflect the measured state (status 4).
- **FR-009**: System MUST move processed HL7 files to an archive folder within the same MinIO bucket after successful import.
- **FR-010**: System MUST mark `Hl7Import` as `failed` with an error message when HL7 parsing fails.
- **FR-011**: System MUST mark `Hl7Import` as `awaiting_registration` when no matching `Measurement` can be found.
- **FR-012**: System MUST skip files already recorded in `hl7_imports` (idempotent scanning).
- **FR-013**: System MUST use Rails credentials for MinIO S3 credentials (never hardcoded).
- **FR-014**: System MUST support a re-linkage mechanism for `awaiting_registration` imports when measurements are later registered.
- **FR-015**: An analyte test-code mapping configuration (HL7 test code → `ProjectId`) MUST be defined in a constants module.

### Key Entities

- **Hl7Import**: Tracks every HL7 file scanned from MinIO. Fields: `measurement_id`, S3 metadata (`s3_key`, `s3_bucket`, `s3_etag`, `file_size`), HL7 metadata (`control_id`, `message_type`, `message_datetime`, `sending_application`, `sending_facility`, `external_order_id`, `hl7_test_code`, `kit_code_extracted`), status (`pending`/`processing`/`completed`/`failed`/`awaiting_registration`/`registration_error`), processing audit (`processed_at`, `error_message`, `processing_stats`, `retry_count`, `last_retry_at`).
- **Measurement**: Existing model — receives updated `Status` and `MeasureDate` after import. Gains `has_one :hl7_import`.
- **AnalyteResult**: Existing model — rows are replaced per measurement on each import. Identified by composite PK (`ResultId`, `AnalyteId`).
- **Result**: Existing model — intermediary between `Measurement` and `AnalyteResult` (PK = `MeasurementId`).
- **Hl7Config**: Constants module defining HL7 test code → ProjectId mapping and archive folder name.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All new HL7 files in the MinIO bucket are detected and recorded within one job-cycle run (no missed files).
- **SC-002**: Analyte values from a valid HL7 file are fully persisted in under 5 seconds per file under normal load.
- **SC-003**: A file already imported is never imported twice (zero duplicate `Hl7Import` records per `s3_key`).
- **SC-004**: Failed imports are traceable — every failure has a stored error message and the original file remains accessible via ActiveStorage.
- **SC-005**: Re-linkage correctly resolves at least 95% of `awaiting_registration` imports once the corresponding measurement is registered.

## Assumptions

- The MinIO bucket used for HL7 imports is separate from the main ActiveStorage bucket (it is a dedicated lab-results bucket accessed with its own credentials under a `hl7_s3` key in Rails credentials).
- The HL7 test code → ProjectId mapping is small and stable enough to live in a `Hl7::Config` constants module; no admin UI is needed.
- `Measurement.Status = 4` represents the "results imported/measured" state in this application's workflow (equivalent to the `completed` status in the source app).
- Notification emails are out of scope for this feature — the `Note` model approach from the source app does not apply here as the `notes` table has a restricted `available_keys` list that would require a constitution amendment.
- The `Result` model (PK = `MeasurementId`) is the intermediary for `AnalyteResult`; creating a `Result` record is part of the import flow alongside `AnalyteResult` creation.
- ActiveStorage archival (moving to archive folder) is done directly via the aws-sdk-s3 gem (copy + delete), not through ActiveStorage APIs, consistent with the source pattern.
- The import is scoped to measurements matching the Lalen partner (institutions in `V1::Common::LALEN_INSTITUTION_IDS`), but the scanner is designed to be partner-agnostic at the scanning level.
