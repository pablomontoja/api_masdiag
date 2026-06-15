# Research: Webhook Scanned PDF Pipeline

**Feature**: `002-webhook-pdf-pipeline`
**Date**: 2026-06-02

---

## 1. Controller inheritance — standalone vs ApplicationController

**Decision**: `ScannedDocsController < ActionController::API` (standalone, not inheriting `ApplicationController`)

**Rationale**: `ApplicationController` enforces HTTP Basic Auth against `ApiAccount` via `authenticate_or_request_with_http_basic`. The webhook endpoint uses a Bearer token stored in Rails credentials. Inheriting `ApplicationController` would fire the Basic Auth `before_action` before our custom check, resulting in a 401 on every valid webhook request.

**Alternatives considered**:
- Inherit `ApplicationController` and skip the auth callback — fragile; a future change to `ApplicationController` could silently re-enable the wrong auth path.
- Add a new concern to `ApplicationController` to detect Bearer vs Basic — couples unrelated auth schemes.
- Standalone controller — clean separation; matches the pattern used internally for `HealthController`.

---

## 2. Job backend — Solid Queue

**Decision**: Solid Queue (already configured in this project)

**Rationale**: The project uses Solid Queue exclusively. The OCR queue is CPU-intensive and low-volume; Solid Queue's DB-backed queue is perfectly adequate. No change needed.

**Configuration needed**: Add an `ocr` queue to Solid Queue config if not already present. Jobs use `retry_on StandardError, wait: :exponentially_longer, attempts: 5` per constitution.

---

## 3. Bearer token storage and comparison

**Decision**: Store token at `Rails.application.credentials.dig(:scan_webhook, :token)`; compare with `ActiveSupport::SecurityUtils.secure_compare`

**Rationale**: Rails credentials are the project-standard secret store (Constitution IV). Constant-time comparison prevents timing attacks even on a LAN.

**Alternatives considered**:
- Environment variable — not the project standard; would require `.env` file management.
- Database-stored token — unnecessary overhead for a single shared secret.

---

## 4. Idempotency anchor

**Decision**: `page_checksum` (sha256 of the single-page PDF), unique DB index + `find_or_initialize_by`

**Rationale**: Since `scanned_docs` stores one row per single-page PDF (no `page_number`/`total_pages`), the sha256 of the page content is the natural deduplication key. A DB-level unique index provides the hard guarantee; `find_or_initialize_by` provides the soft check before save.

**Race condition handling**: Two concurrent identical posts will both hit `find_or_initialize_by` before either saves. The unique index will reject the second `save!` with `ActiveRecord::RecordNotUnique`. The controller should rescue this and return `202 "duplicate"` rather than `422`.

**Implementation note**: Wrap `doc.save!` in a rescue for `ActiveRecord::RecordNotUnique` in the Ingestor to handle the race.

---

## 5. ActiveStorage attachment strategy

**Decision**: `has_one_attached :page_pdf` and `has_one_attached :markdown` on `ScannedDoc`

**Rationale**: ActiveStorage is already configured with MinIO in production and Disk in test. Two separate attachments allow independent lifecycle management — `page_pdf` is attached at ingest time, `markdown` is attached later by the OCR job.

**File content type**: `page_pdf` → `application/pdf`; `markdown` → `text/markdown`.

**Variants**: Not needed — both attachments are served as-is (PDFs rendered by browser/viewer; Markdown consumed by downstream consumers).

---

## 6. OCR approach — llama-server integration

**Decision**: HTTP call to local `llama-server` at `OCR_ENDPOINT` (default `http://127.0.0.1:8080/v1/chat/completions`) using OpenAI-compatible API

**Rationale**: `llama-server` exposes an OpenAI-compatible API; `net/http` stdlib is sufficient for a single-endpoint HTTP client. No gem needed. The `read_timeout: 600` is generous because CPU inference on small models takes 10–120 seconds per page.

**Model selection** (out of Rails scope — ops concern):
- `Dots.OCR` (~1.8B, GGUF Q8_0) — recommended lightweight start
- `GLM-OCR` — strong for structured documents
- `Qwen3-VL-2B` — general VLM alternative

**Fallback**: If `llama-server` is unavailable, `OcrJob` marks the record `failed` + records `processing_error`, then re-raises so Solid Queue retries with exponential backoff. The `page_pdf` is preserved, so OCR can be re-run at any time by re-enqueuing.

---

## 7. PDF rasterization — pdftoppm

**Decision**: `pdftoppm -png -r 200 -singlefile <pdf_path> <output_base>` via `Open3.capture3`

**Rationale**: `poppler-utils` is already a dependency (used by the Bash watcher for `pdfseparate`). `pdftoppm` rasterizes a single-page PDF to PNG at 200 DPI — sufficient for most OCR models. `-singlefile` produces exactly one `<base>.png` without page-number suffix.

**Temp file management**: Use `Dir.mktmpdir` + `ensure FileUtils.remove_entry` to guarantee cleanup regardless of exceptions.

**Alternatives considered**:
- ImageMagick/MiniMagick — extra gem, Ghostscript dependency; poppler is already present.
- Vips (ruby-vips) — no native PDF support without Ghostscript.

---

## 8. sample_id validation — defensive ignore

**Decision**: In `Ingestor#resolved_sample_id`, check `Sample.exists?(id)` and return `nil` if the reference is unknown.

**Rationale**: An unknown `sample_id` from a misconfigured watcher must not cause a 422 that the watcher retries forever (it cannot self-heal). Storing with `NULL` is safer and the Bash script logs the failure. The association is `optional: true` in the model.

**Alternatives considered**:
- Validate and return 422 — watcher would retry indefinitely, consuming resources.
- Skip validation entirely — no worse than the chosen approach; explicit check is slightly safer.

---

## 9. Routes namespace — webhook vs v1

**Decision**: `namespace :webhook { resources :scanned_docs, only: [:create] }` → `POST /webhook/scanned_docs`

**Rationale**: Per the design specification, the endpoint deliberately avoids the `v1` namespace (which uses HTTP Basic Auth against `ApiAccount`). A new `webhook` namespace cleanly separates machine-to-machine webhook endpoints from tenant-facing API endpoints.

**No namespace concern needed**: Unlike `v1`/`fv1`/`lalen`, the `webhook` namespace has its own auth scheme entirely (Bearer) and requires no `MasdiagCheck`/`LalenCheck`-style concern.

---

## 10. Resolved: no new gems required

All implementation needs are met by:
- Ruby stdlib: `net/http`, `open3`, `base64`, `tmpdir`, `fileutils`
- Existing gems: `activestorage`, `activejob`, `activesupport`
- System tool: `pdftoppm` (from `poppler-utils`)

No Gemfile changes needed.

---

## 11. FK to `Samples` — legacy primary key incompatibility

**Decision**: Define the foreign key manually in the migration; do NOT use `t.references :sample, foreign_key: true`.

**Rationale**: The existing `Samples` table uses a legacy schema with `primary_key: "Id", id: :integer` and the table name is capitalised (`"Samples"`). Rails' `t.references :sample, foreign_key: true` assumes a conventional `samples.id bigint` target and will generate an invalid FK constraint.

**Correct migration snippet**:
```ruby
t.integer :sample_id, null: true
add_index :scanned_docs, :sample_id
add_foreign_key :scanned_docs, "Samples", column: :sample_id, primary_key: "Id"
```

`Sample.exists?(id)` still works correctly — the model already sets `self.primary_key = "Id"`.

**Alternatives considered**:
- `t.references :sample, foreign_key: false` + manual index — omits DB-level FK integrity, less safe.
- Skip FK constraint entirely — acceptable if legacy FK constraints are not used elsewhere, but the explicit FK is preferred for data integrity.

---

## 12. `Ingestor` — ApplicationService inheritance

**Decision**: `ScannedDocs::Ingestor` will NOT inherit from `ApplicationService`; the deviation is documented in Complexity Tracking.

**Rationale**: `ApplicationService` returns `OpenStruct` with `success?`/`payload`/`error`. The Ingestor needs to return `status` ("stored" | "duplicate") and `scanned_doc_id` — fields not covered by the base `payload` convention. Using `OpenStruct` would work but the semantic contract would be opaque. A dedicated `Result` struct (`Struct.new(..., keyword_init: true)`) is explicit and testable.

**Constitution note**: Principle II requires inheriting `ApplicationService`. This deviation must appear in Complexity Tracking with justification.

**Alternatives considered**:
- Inherit `ApplicationService` and pack `{ status:, id: }` into `payload` — works but callers must know the payload shape, making the interface implicit.
- Add a `status` accessor to `ApplicationService` — invasive change to a base class shared by the whole project.

---

## 13. `ScannedDocsController` — missing Response and ExceptionHandler mixins

**Decision**: Explicitly `include Response` and `include ExceptionHandler` in `ScannedDocsController`.

**Rationale**: These concerns are mixed into all controllers via `ApplicationController`. Since `ScannedDocsController` inherits `ActionController::API` directly (see decision 1), it misses them. The constitution (Development Workflow §7) mandates `json_response` — inline `render json:` is prohibited.

**`ExceptionHandler`** rescues `ActiveRecord::RecordNotFound` and `ActiveRecord::RecordInvalid` globally, which is desirable for the webhook controller too. However, it also calls `Sentry.capture_exception` — acceptable since we want production error visibility even for this endpoint.

**Implementation**:
```ruby
class ScannedDocsController < ActionController::API
  include Response
  include ExceptionHandler
  include ActiveStorage::SetCurrent
  before_action :authenticate_webhook!
  # ...
end
```

`ActiveStorage::SetCurrent` is also needed so that URL helpers for attachments work correctly (same as `ApplicationController`).

---

## 14. ActiveStorage attach order — save! before attach

**Decision**: Call `doc.save!` first, then `doc.page_pdf.attach(...)`.

**Rationale**: In Rails 7.0, calling `has_one_attached` attach before `save!` on a new record creates the blob in the storage backend (MinIO) before the DB record is committed. If `save!` then raises (e.g., uniqueness violation from a race), the orphaned blob remains in MinIO with no associated record. Reversing the order ensures the DB row exists before any storage write occurs.

**Correct sequence in Ingestor**:
```ruby
doc.assign_attributes(...)
doc.save!                          # DB row committed first
doc.page_pdf.attach(io: ..., ...)  # storage write only after successful save
ScannedDocs::OcrJob.perform_later(doc.id)
```

**Note on the race**: `ActiveRecord::RecordNotUnique` can still be raised by `save!` (two concurrent posts with the same checksum). This must be rescued in `Ingestor#call` and converted to a `"duplicate"` result — not re-raised as a 422.

---

## 15. `captured_at` — explicit string parsing

**Decision**: Parse `captured_at` explicitly in the Ingestor using `Time.parse` before assigning to the model.

**Rationale**: The Bash watcher sends `captured_at=$(date -Is)` (ISO 8601 with timezone offset, e.g. `2026-06-02T14:30:00+02:00`). `ActiveRecord` will attempt to cast the string when assigning to a `datetime` column, but the cast behaviour depends on the DB adapter and Rails version. A silent `nil` on a malformed string is harder to debug than an explicit parse error caught in the Ingestor.

**Implementation**:
```ruby
captured_at: (@params[:captured_at].present? ? Time.parse(@params[:captured_at]) : nil),
```

Wrap in `rescue ArgumentError => nil` if tolerance for bad timestamps is preferred over a 422.

---

## 16. Serializer — ScannedDocResource

**Decision**: Create a minimal `ScannedDocResource` (Alba) for the webhook response; do not use inline `render json:`.

**Rationale**: The constitution prohibits inline `render json:` in controllers (Development Workflow §7). Even for a simple `{ status:, id: }` response, using `json_response` with a resource is the project standard. A thin resource makes future additions (e.g. returning `source_filename` or `status` label) non-breaking.

**Minimum viable resource**:
```ruby
# app/resources/scanned_doc_resource.rb
class ScannedDocResource
  include Alba::Resource
  attributes :id, :status
end
```

The controller passes `result.scanned_doc` (or an OpenStruct equivalent) rather than a raw hash.

**Alternatives considered**:
- Return a plain hash via `json_response({...})` — technically satisfies `json_response` usage, avoids a new file. Acceptable if the team treats the webhook response as infrastructure rather than a domain resource. Document the choice.

---

## 17. Database adapter — MySQL

**Decision**: All migration types must account for MySQL constraints (charset, collation, integer FKs).

**Rationale**: The schema.rb confirms MySQL (`charset: "utf8"`, `force: :cascade` on all legacy tables). Key implications:
- `text` columns in MySQL have size variants (`text`, `mediumtext`, `longtext`) — `processing_error: :text` is fine (64 KB limit).
- `datetime` precision: use `datetime(6)` if microsecond precision is needed, otherwise plain `datetime` matches existing schema columns.
- The unique index on `page_checksum` (string/varchar) in MySQL: sha256 hex is 64 chars, well within the 255-char index limit — no prefix index needed.
- Add `charset: "utf8mb4"` to the migration's `create_table` to match the project's encoding standard for new tables.

## 18. Dockerfile — poppler-utils

**Decision**: Add `poppler-utils` to the project Dockerfile.

**Rationale**: The project currently has no Dockerfile. `pdftoppm` (part of `poppler-utils`) is a required system dependency for `PageRasterizer`. Without it in the image, the OCR job silently fails at the shell-out call. The Dockerfile must be created and `poppler-utils` installed as part of this feature.

**Dockerfile pattern** (Rails 7 on Debian/Ubuntu base):

```dockerfile
FROM ruby:3.1.2-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      default-libmysqlclient-dev \
      nodejs \
      poppler-utils \
    && rm -rf /var/lib/apt/lists/*
```

**Placement**: `poppler-utils` goes in the same `apt-get install` layer as other system dependencies to keep image layers minimal. It must be present in both the Rails web process image and the Solid Queue worker image (or a single shared image covering both).

**Alternatives considered**:
- Document as a manual server-side install — works for bare-metal deploys but breaks containerised environments; a Dockerfile is the correct long-term solution.
- Separate worker image with only `poppler-utils` — premature complexity; a single shared image is simpler at this scale.
