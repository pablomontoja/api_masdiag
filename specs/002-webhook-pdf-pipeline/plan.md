# Implementation Plan: Webhook Scanned PDF Pipeline (Rails Part)

**Branch**: `002-webhook-pdf-pipeline` | **Date**: 2026-06-02 | **Spec**: [spec.md](spec.md)

**Input**: Implementation design from user-provided docs — Scanned PDF Pipeline v2

**Scope**: This plan covers **only the Rails side** of the pipeline. The Bash scan-watcher script is out of scope here (documented in the design docs but not implemented in this repo).

---

## Summary

A new `api` + `webhook` namespace receives single-page PDF uploads from a LAN-local Bash watcher via multipart POST authenticated with a Bearer token. Each page is stored as a `ScannedDoc` ActiveRecord with an `ActiveStorage` attachment (`page_pdf`). After storage, an async job (`ScannedDocs::OcrJob`) rasterizes the PDF page with `pdftoppm`, sends the PNG to a local `llama-server` (CPU, OpenAI-compatible API), and attaches the resulting Markdown as a second `ActiveStorage` attachment (`markdown`). Idempotency is enforced via a unique index on `page_checksum` (sha256 of the single-page PDF).

---

## Technical Context

**Language/Version**: Ruby 3.1.2 / Rails 7.0.8

**Primary Dependencies**:
- ActiveStorage (MinIO in production, Disk in test/dev) — already configured
- Solid Queue — already configured as job backend
- `net/http`, `open3`, `base64` — stdlib, no new gems needed
- `poppler-utils` system package (`pdftoppm`) — required on the host; added to Dockerfile

**Storage**: MySQL (existing), MinIO via ActiveStorage (existing)

**Testing**: RSpec + FactoryBot (existing conventions)

**Target Platform**: Linux server (LAN-only, not internet-facing)

**Project Type**: Rails 7 API-only web service

**Performance Goals**: Webhook response < 500ms (file saved + job enqueued); OCR throughput is CPU-bound and asynchronous (seconds to minutes per page — acceptable)

**Constraints**: No rate limiting (LAN-only per design decision); Bearer token auth only (no HMAC); no GPU

**Scale/Scope**: Low volume (scanner-driven, one PDF at a time per cron minute)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Rails Conventions | New `webhook` namespace follows Rails namespace conventions; controller under `app/controllers/webhook/`; routes use `namespace` blocks. Migration uses explicit FK definition to match legacy `Samples` table conventions. | ✅ PASS |
| II. Service-Object Architecture | Controller is thin (auth + delegate to `ScannedDocs::Ingestor`); business logic in service; OCR logic split into `PageRasterizer` + `OcrClient` services; `OcrJob` is async-only. `Ingestor` uses a dedicated `Result` struct instead of `ApplicationService` base — justified deviation documented below. | ⚠️ JUSTIFIED — see Complexity Tracking |
| III. Test-First | Request specs, service unit specs, and job unit specs required before implementation | ✅ PASS — enforced in tasks |
| IV. Security & Secrets | Bearer token stored in Rails credentials (`scan_webhook: token`); constant-time compare via `ActiveSupport::SecurityUtils.secure_compare`; no secrets in source | ✅ PASS |
| V. Multi-Tenancy Integrity | `ScannedDoc` is NOT institution-scoped — it's a machine-to-machine ingest endpoint, not a tenant-facing resource. The `sample_id` FK optionally links to the existing `Samples` table. | ⚠️ JUSTIFIED — see Complexity Tracking |
| VI. Layered Architecture | Controller includes `Response` + `ExceptionHandler` concerns; uses `json_response` (no inline `render json:`); response serialized via `ScannedDocResource` (Alba). Job → PageRasterizer service → OcrClient service → model update. All layers within abstraction thresholds. | ✅ PASS |

**Constitution Check: PASS** (with two justified deviations — see Complexity Tracking)

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| `ScannedDoc` not institution-scoped (Principle V) | The webhook is a machine-to-machine LAN endpoint; the sender is a Bash watcher, not a tenant API client. No `ApiAccount` authenticates this request — it uses a shared Bearer token. Institution scoping is irrelevant and would require fabricating a fake institution context. | Faking an institution context would add coupling with no tenant-isolation benefit; the `sample_id` FK is optional and provides indirect linkage to the tenant domain if needed. |
| `ScannedDocsController` inherits `ActionController::API` directly (not `ApplicationController`) | `ApplicationController` enforces HTTP Basic Auth against `ApiAccount`, which is incompatible with Bearer token auth for this machine endpoint. `Response`, `ExceptionHandler`, and `ActiveStorage::SetCurrent` are included manually. | Inheriting `ApplicationController` and skipping the auth callback would be fragile; a future change to `ApplicationController` could silently re-enable the wrong auth path. |
| `ScannedDocs::Ingestor` does not inherit `ApplicationService` (Principle II) | `ApplicationService` returns `OpenStruct` with `success?`/`payload`/`error`. The Ingestor must convey `status` ("stored" \| "duplicate") and `scanned_doc_id` — semantics not expressible via the base `payload` field without implicit conventions. A dedicated `Result` struct makes the contract explicit and IDE/test-friendly. | Packing `{ status:, id: }` into `payload` works mechanically but makes callers dependent on undocumented shape. Extending `ApplicationService` base class to support `status` would be an invasive, project-wide change. |

---

## Project Structure

### Documentation (this feature)

```text
specs/002-webhook-pdf-pipeline/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── webhook_api.md   # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── api/
│       └── webhook/
│           └── scanned_docs_controller.rb   # includes Response, ExceptionHandler, ActiveStorage::SetCurrent
├── models/
│   └── scanned_doc.rb
├── resources/
│   └── scanned_doc_resource.rb              # Alba serializer for webhook response
├── services/
│   └── scanned_docs/
│       ├── ingestor.rb                      # Result struct (no ApplicationService inheritance — see Complexity Tracking)
│       ├── page_rasterizer.rb
│       └── ocr_client.rb
└── jobs/
    └── scanned_docs/
        └── ocr_job.rb

db/migrate/
└── XXXXXXXXXXXXXX_create_scanned_docs.rb    # MySQL: manual FK to "Samples"."Id"; charset utf8mb4

Dockerfile                                   # add poppler-utils installation

spec/
├── requests/
│   └── api/webhook/
│       └── scanned_docs_spec.rb
├── models/
│   └── scanned_doc_spec.rb
├── resources/
│   └── scanned_doc_resource_spec.rb
├── services/
│   └── scanned_docs/
│       ├── ingestor_spec.rb
│       ├── page_rasterizer_spec.rb
│       └── ocr_client_spec.rb
└── jobs/
    └── scanned_docs/
        └── ocr_job_spec.rb
```

---
