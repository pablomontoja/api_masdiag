# Data Model: Webhook Scanned PDF Pipeline

**Feature**: `002-webhook-pdf-pipeline`
**Date**: 2026-06-02

---

## Entity: ScannedDoc

**Table**: `scanned_docs`
**Description**: One row per single-page PDF received from the scan-watcher. Carries the raw page PDF and, once processed, an OCR-produced Markdown transcription.

### Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | bigint PK | no | autoincrement | |
| `source_filename` | string | no | — | Original multi-page PDF filename (provenance) |
| `page_checksum` | string | no | — | sha256 of the single-page PDF; idempotency key |
| `document_key` | string | yes | NULL | sha256 of the source PDF (optional provenance link) |
| `status` | integer | no | 0 | Enum: ready(0), ocr_pending(1), transcribed(2), failed(9) |
| `source` | string | no | "scan_watcher" | Origin identifier |
| `sample_id` | bigint FK | yes | NULL | Optional FK → `samples.id` |
| `captured_at` | datetime | yes | NULL | Timestamp from scanner (ISO 8601 string in form) |
| `received_at` | datetime | yes | NULL | Set by Rails at ingest time |
| `ocr_started_at` | datetime | yes | NULL | Set by OcrJob at start |
| `transcribed_at` | datetime | yes | NULL | Set by OcrJob on success |
| `processing_error` | text | yes | NULL | Last error message from OcrJob |
| `created_at` | datetime | no | — | Rails timestamp |
| `updated_at` | datetime | no | — | Rails timestamp |

### Indexes

| Index | Columns | Unique | Notes |
|-------|---------|--------|-------|
| `index_scanned_docs_on_page_checksum` | `page_checksum` | YES | Idempotency enforced at DB level |
| `index_scanned_docs_on_status` | `status` | no | Queue filtering |
| `index_scanned_docs_on_sample_id` | `sample_id` | no | Created by `t.references` |

### Foreign Keys

| Column | References | On Delete |
|--------|-----------|-----------|
| `sample_id` | `"Samples"."Id"` (integer PK, legacy schema) | RESTRICT (default) |

> **Migration note**: Use `add_foreign_key :scanned_docs, "Samples", column: :sample_id, primary_key: "Id"` — do NOT use `t.references :sample, foreign_key: true` which assumes a conventional `samples.id bigint` target.

### ActiveStorage Attachments

| Name | Content Type | Attached By | Notes |
|------|-------------|------------|-------|
| `page_pdf` | `application/pdf` | `ScannedDocs::Ingestor` | Stored at ingest; never replaced |
| `markdown` | `text/markdown` | `ScannedDocs::OcrJob` | Attached after OCR; re-attachable if OCR re-run |

### Status State Machine

```
[receive page]
    │
    ▼
  ready (0)
    │ OcrJob enqueued
    ▼
ocr_pending (1)
    │
    ├──[success]──► transcribed (2)
    │
    └──[error]────► failed (9)
                        │
                        └──[retry]──► ocr_pending (1)
```

### Validations

| Attribute | Rule |
|-----------|------|
| `source_filename` | presence |
| `page_checksum` | presence, uniqueness |
| `status` | inclusion in enum values |

### Associations

```ruby
belongs_to :sample, optional: true
has_one_attached :page_pdf
has_one_attached :markdown
```

### Scopes

```ruby
scope :awaiting_ocr, -> { where(status: :ready) }
```

---

## Relationships to Existing Entities

```
Sample (existing)
  └── has_many :scanned_docs (optional)

ScannedDoc (new)
  ├── belongs_to :sample (optional)
  ├── has_one_attached :page_pdf
  └── has_one_attached :markdown
```

The `samples` table and `Sample` model already exist in the project. No changes to `Sample` are required — the relationship is navigable from `ScannedDoc` only. Adding `has_many :scanned_docs` to `Sample` is optional and not required for this feature.

---

## Service Layer Entities

### ScannedDocs::Ingestor

**Input**: `params` (hash of form fields), `file` (ActionDispatch::Http::UploadedFile)

**Output**: `Result` struct with `success?`, `status` ("stored" | "duplicate"), `scanned_doc_id`, `error`

**Side effects**: Creates/finds `ScannedDoc`; saves to DB first; then attaches `page_pdf`; enqueues `OcrJob`

> **Attach order**: `save!` is called before `page_pdf.attach` to prevent orphaned blobs in MinIO if the DB write fails.

### ScannedDocs::PageRasterizer

**Input**: `attachment` (ActiveStorage::Attached::One)

**Output**: PNG bytes (binary string)

**Side effects**: Writes/reads temp files; shells out to `pdftoppm`

### ScannedDocs::OcrClient

**Input**: PNG bytes (binary string)

**Output**: Markdown string

**Side effects**: HTTP POST to `llama-server`

### ScannedDocs::OcrJob

**Input**: `scanned_doc_id` (integer)

**Output**: none (side-effectful)

**Side effects**: Updates `ScannedDoc` status; attaches `markdown`; calls `PageRasterizer` + `OcrClient`
