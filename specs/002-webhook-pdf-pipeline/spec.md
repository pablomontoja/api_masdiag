# Feature Specification: Webhook Scanned PDF Pipeline

**Feature Branch**: `002-webhook-pdf-pipeline`

**Created**: 2026-06-02

**Status**: Draft

**Input**: A scanner-side Bash watcher splits incoming PDFs into single pages and POSTs each page to a Rails webhook on the local network. Rails stores each page as a `ScannedDoc` record with an ActiveStorage PDF attachment, then asynchronously runs OCR via a local llama.cpp server and attaches the resulting Markdown.

## User Scenarios & Testing

### User Story 1 - PDF Page Ingest via Webhook (Priority: P1)

The scan-watcher POSTs a single-page PDF to the Rails webhook. Rails authenticates the Bearer token, stores the page as a `ScannedDoc` record with the PDF attached, and responds 202. Duplicate pages (same sha256) return 202 with `"duplicate"` status — no second record is created.

**Why this priority**: This is the core pipeline entry point. Nothing else works without it. Delivery of this story alone gives a usable ingest endpoint.

**Independent Test**: Send a multipart POST with a valid Bearer token and a single-page PDF. Verify 202 response with `{ "status": "stored", "id": <n> }`. Re-send the same file — verify 202 with `{ "status": "duplicate", "id": <n> }`. Send with wrong token — verify 401.

**Acceptance Scenarios**:

1. **Given** a valid Bearer token and a single-page PDF, **When** POST `/webhook/scanned_docs`, **Then** respond 202 `{ status: "stored", id: N }` and create one `ScannedDoc` with `page_pdf` attached and status `ready`.
2. **Given** the same page is POSTed a second time (same `page_checksum`), **When** POST `/webhook/scanned_docs`, **Then** respond 202 `{ status: "duplicate", id: N }` and leave the record count unchanged.
3. **Given** a wrong or missing Bearer token, **When** POST `/webhook/scanned_docs`, **Then** respond 401 `{ error: "unauthorized" }`.
4. **Given** a file that is not a PDF (no `%PDF-` magic bytes), **When** POST, **Then** respond 422 `{ error: "not a PDF" }`.
5. **Given** a file larger than 25 MB, **When** POST, **Then** respond 422 `{ error: "file too large" }`.
6. **Given** a valid request with an unknown `sample_id`, **When** POST, **Then** respond 202 `stored`, store the record with `sample_id: NULL`.

---

### User Story 2 - Async OCR Transcription (Priority: P2)

After a page is stored (status `ready`), a background job rasterizes the PDF page to PNG, sends it to the local llama-server, and attaches the resulting Markdown. The record transitions `ready → ocr_pending → transcribed`. On failure the record becomes `failed` with `processing_error` set, and the job retries with backoff.

**Why this priority**: Adds value on top of US1 (raw storage). The PDF is preserved regardless of OCR outcome, so US2 can be developed and retried independently.

**Independent Test**: Create a `ScannedDoc` fixture with `page_pdf` attached. Enqueue `OcrJob`. Stub `OcrClient` to return a fixed Markdown string. Verify status becomes `transcribed`, `markdown` attachment is present with the expected content.

**Acceptance Scenarios**:

1. **Given** a `ScannedDoc` with status `ready`, **When** `OcrJob` runs, **Then** status becomes `ocr_pending` during processing, then `transcribed` on success, and `markdown` is attached.
2. **Given** `OcrClient` raises an error, **When** `OcrJob` runs, **Then** status becomes `failed`, `processing_error` records the message, and the job re-raises for Solid Queue retry.
3. **Given** a `ScannedDoc` already `transcribed`, **When** `OcrJob` runs again, **Then** job exits early without re-processing.

---

### Edge Cases

- File still being written when POST arrives — mitigated by Bash watcher stability check; Rails side validates magic bytes and size.
- Two concurrent POSTs with the same `page_checksum` — unique DB index raises `RecordNotUnique`; Ingestor rescues and returns `"duplicate"`.
- `sample_id` references a non-existent sample — stored as NULL, no error.
- `llama-server` unreachable — OcrJob marks `failed` and Solid Queue retries with exponential backoff.
- OCR produces empty string — attach empty Markdown, status `transcribed`; downstream consumers handle emptiness.

## Requirements

### Functional Requirements

- **FR-001**: System MUST accept multipart POST to `/webhook/scanned_docs` with a PDF file, `page_checksum`, and `source_filename`.
- **FR-002**: System MUST authenticate every request via Bearer token (constant-time comparison against Rails credentials).
- **FR-003**: System MUST be idempotent on `page_checksum`: a second POST with the same checksum MUST return 202 `"duplicate"` without creating a new record.
- **FR-004**: System MUST validate the uploaded file: reject non-PDFs (magic bytes) and files > 25 MB with 422.
- **FR-005**: System MUST accept an optional `sample_id` and associate the record with the corresponding sample; silently ignore unknown IDs.
- **FR-006**: System MUST enqueue an async OCR job after storing a new page.
- **FR-007**: OCR job MUST rasterize the PDF page to PNG and send it to the local llama-server at `OCR_ENDPOINT`.
- **FR-008**: OCR job MUST attach the returned Markdown and transition the record status to `transcribed`.
- **FR-009**: OCR job MUST handle llama-server failures by marking the record `failed`, recording the error, and re-raising for retry.

### Key Entities

- **ScannedDoc**: One row per single-page PDF. Carries status enum (ready/ocr_pending/transcribed/failed), ActiveStorage `page_pdf` and `markdown` attachments, optional `sample_id` FK.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A valid single-page PDF POST returns 202 in under 500 ms (file saved + job enqueued).
- **SC-002**: A duplicate POST (same checksum) returns 202 without creating a new DB record or re-attaching the file.
- **SC-003**: An invalid Bearer token always returns 401, regardless of request payload.
- **SC-004**: The `page_pdf` attachment is always preserved even when OCR fails, allowing re-processing at any time.

## Assumptions

- The Bash scan-watcher (out of scope) handles PDF splitting; Rails always receives single-page PDFs.
- `samples` table and `Sample` model already exist; `ScannedDoc` adds an optional FK to it.
- ActiveStorage is already configured with MinIO (production) and Disk (test/dev).
- Solid Queue is the job backend; no Sidekiq or Redis required.
- The endpoint is LAN-only; no rate limiting or TLS termination is required.
- `poppler-utils` (`pdftoppm`) is available in the runtime environment (Dockerfile or bare-metal).
- A local `llama-server` is running and accessible at `OCR_ENDPOINT`; Rails does not manage the OCR server lifecycle.
