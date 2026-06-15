# Tasks: Webhook Scanned PDF Pipeline

**Input**: Design documents from `specs/002-webhook-pdf-pipeline/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅

**Tests**: Included — project constitution mandates test-first (RED-GREEN-REFACTOR).

**Organization**: Tasks grouped by user story; TDD order enforced (specs before implementation).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to (US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Runtime environment and database foundation — required before any Rails code.

- [x] T001 Update `Dockerfile` with `ruby:3.1.2-alpine` or `ruby:3.1.2-slim`, install system dependencies including `poppler-utils`, `build-essential`, `default-libmysqlclient-dev`
- [ ] T002 [P] Add `scan_webhook: token` key structure to Rails credentials (`rvm use ruby-3.1.2 && bin/rails credentials:edit`) and document expected key path in `quickstart.md`
- [x] T003 [P] Verify Solid Queue `ocr` queue is present in Solid Queue config — check `config/solid_queue.yml` or equivalent; add `ocr` queue entry if missing — worker uses `queues: "*"`, no separate entry needed

**Checkpoint**: Dockerfile builds; `pdftoppm` available inside container; credentials key structure defined; `ocr` queue configured.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and model — required before US1 or US2 can proceed.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Write migration spec asserting `scanned_docs` table structure: columns, unique index on `page_checksum`, status default, FK to `"Samples"."Id"` — file: `spec/db/migrate/create_scanned_docs_spec.rb` (or use schema inspection in `spec/models/scanned_doc_spec.rb`)
- [x] T005 Generate and write migration `create_scanned_docs`: `source_filename`, `page_checksum` (unique index), `document_key`, `status` (integer, default 0), `source` (default "scan_watcher"), `sample_id` (integer nullable), `captured_at`, `received_at`, `ocr_started_at`, `transcribed_at`, `processing_error` (text), timestamps; manual FK via `add_foreign_key :scanned_docs, "Samples", column: :sample_id, primary_key: "Id"`; `charset: "utf8mb4"` on `create_table` — file: `db/migrate/20260602184748_create_scanned_docs.rb`
- [x] T006 Run `rvm use ruby-3.1.2 && bin/rails db:migrate` and `rvm use ruby-3.1.2 && bin/rails db:migrate RAILS_ENV=test`
- [x] T007 Write `ScannedDoc` model spec: enum values, presence validations, uniqueness on `page_checksum`, `belongs_to :sample, optional: true`, `has_one_attached :page_pdf`, `has_one_attached :markdown`, `awaiting_ocr` scope — file: `spec/models/scanned_doc_spec.rb`
- [x] T008 Implement `ScannedDoc` model: enum `{ ready: 0, ocr_pending: 1, transcribed: 2, failed: 9 }`, validations, associations, `awaiting_ocr` scope, `transcription` helper — file: `app/models/scanned_doc.rb`
- [x] T009 [P] Create `ScannedDoc` FactoryBot factory with traits: `:with_page_pdf`, `:ocr_pending`, `:transcribed`, `:failed` — file: `spec/factories/scanned_doc_factory.rb`
- [x] T010 [P] Create minimal `ScannedDocResource` Alba serializer exposing `id` and `status` — file: `app/resources/scanned_doc_resource.rb`

**Checkpoint**: `rvm use ruby-3.1.2 && bundle exec rspec spec/models/scanned_doc_spec.rb` passes; migration applied; factory works.

---

## Phase 3: User Story 1 — PDF Page Ingest via Webhook (Priority: P1) 🎯 MVP

**Goal**: A valid Bearer-authenticated multipart POST stores a single-page PDF as a `ScannedDoc` with `page_pdf` attached and enqueues `OcrJob`. Duplicate checksums return `"duplicate"` without a second record.

**Independent Test**: `rvm use ruby-3.1.2 && bundle exec rspec spec/requests/webhook/scanned_docs_spec.rb` — covers 202/stored, 202/duplicate, 401, 422.

### Specs for User Story 1

- [x] T011 [P] [US1] Write request spec: POST `/webhook/scanned_docs` — happy path (202 stored, ScannedDoc created, page_pdf attached, OcrJob enqueued); duplicate checksum (202 duplicate, count unchanged); wrong token (401); missing checksum (422); non-PDF bytes (422); file > 25 MB (422); unknown sample_id (202 stored, sample_id NULL) — file: `spec/requests/webhook/scanned_docs_spec.rb`
- [x] T012 [P] [US1] Write `ScannedDocs::Ingestor` unit spec: stores new doc (save! before attach); returns duplicate for existing checksum; rescues `RecordNotUnique` race and returns duplicate; resolves unknown sample_id to nil; validates magic bytes; validates size — file: `spec/services/scanned_docs/ingestor_spec.rb`

### Implementation for User Story 1

- [x] T013 [US1] Add `webhook` namespace routes to `config/routes.rb`: `namespace :webhook { resources :scanned_docs, only: [:create] } }`
- [x] T014 [US1] Implement `ScannedDocs::Ingestor` service (custom `Result` struct, NOT inheriting `ApplicationService` — see research.md §12): `validate!` (magic bytes, size, checksum presence); `find_or_initialize_by(page_checksum:)`; rescue `ActiveRecord::RecordNotUnique`; `save!` before `page_pdf.attach`; `resolved_sample_id` with `Sample.exists?` guard; `captured_at` parsed via `Time.parse`; enqueue `ScannedDocs::OcrJob` — file: `app/services/scanned_docs/ingestor.rb`
- [x] T015 [US1] Implement `Webhook::ScannedDocsController`: inherit `ActionController::API`; include `Response`, `ExceptionHandler`, `ActiveStorage::SetCurrent`; `authenticate_webhook!` via `secure_compare`; thin `create` action delegating to `ScannedDocs::Ingestor`; respond via `json_response` with `ScannedDocResource` — file: `app/controllers/webhook/scanned_docs_controller.rb`

**Checkpoint**: `rvm use ruby-3.1.2 && bundle exec rspec spec/requests/webhook/scanned_docs_spec.rb` green; manual curl smoke test from `quickstart.md` passes.

---

## Phase 4: User Story 2 — Async OCR Transcription (Priority: P2)

**Goal**: After a page is stored, `OcrJob` rasterizes the PDF to PNG, sends it to llama-server, and attaches the Markdown. Status transitions `ready → ocr_pending → transcribed` (or `failed` on error).

**Independent Test**: `rvm use ruby-3.1.2 && bundle exec rspec spec/jobs/scanned_docs/ocr_job_spec.rb spec/services/scanned_docs/page_rasterizer_spec.rb spec/services/scanned_docs/ocr_client_spec.rb` — all stubs, no llama-server required.

### Specs for User Story 2

- [x] T016 [P] [US2] Write `ScannedDocs::PageRasterizer` spec: stub `Open3.capture3` returning success; verify PNG bytes returned; verify temp dir cleanup; verify error raised on non-zero exit — file: `spec/services/scanned_docs/page_rasterizer_spec.rb`
- [x] T017 [P] [US2] Write `ScannedDocs::OcrClient` spec: stub `Net::HTTP` returning valid JSON response; verify Markdown string extracted; verify error raised on non-200 response — file: `spec/services/scanned_docs/ocr_client_spec.rb`
- [x] T018 [P] [US2] Write `ScannedDocs::OcrJob` spec: stubs `PageRasterizer` and `OcrClient`; verifies status transitions (ready→ocr_pending→transcribed); verifies `markdown` attached; verifies `failed` + `processing_error` set on error + re-raises; verifies early exit when already `transcribed` — file: `spec/jobs/scanned_docs/ocr_job_spec.rb`

### Implementation for User Story 2

- [x] T019 [P] [US2] Implement `ScannedDocs::PageRasterizer`: `attachment.open` block; `Dir.mktmpdir` + `ensure FileUtils.remove_entry`; shell out `pdftoppm -png -r 200 -singlefile` via `Open3.capture3`; return PNG bytes — file: `app/services/scanned_docs/page_rasterizer.rb`
- [x] T020 [P] [US2] Implement `ScannedDocs::OcrClient`: `Net::HTTP` POST to `OCR_ENDPOINT`; base64-encode PNG; OpenAI-compatible payload with OCR prompt; `read_timeout: 600`; raise on non-2xx; extract `choices[0].message.content` — file: `app/services/scanned_docs/ocr_client.rb`
- [x] T021 [US2] Implement `ScannedDocs::OcrJob`: `queue_as :ocr`; `retry_on StandardError, wait: :exponentially_longer, attempts: 5`; guard for `page_pdf.attached?` and `transcribed?`; `update!(status: :ocr_pending, ocr_started_at:)`; call `PageRasterizer` → `OcrClient`; `markdown.attach`; `update!(status: :transcribed, transcribed_at:)`; rescue block sets `failed` + `processing_error` then re-raises — file: `app/jobs/scanned_docs/ocr_job.rb`

**Checkpoint**: `rvm use ruby-3.1.2 && bundle exec rspec spec/jobs/scanned_docs/ spec/services/scanned_docs/` green; `ScannedDoc.last.status` transitions correctly in console with stubbed client.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, documentation, and integration verification.

- [x] T022 [P] Update `quickstart.md` with confirmed Solid Queue queue name and any deviations found during implementation — file: `specs/002-webhook-pdf-pipeline/quickstart.md`
- [x] T023 [P] Update `config/routes.rb` entry in `CLAUDE.md` namespace table to document the new `webhook` namespace — file: `CLAUDE.md`
- [x] T024 Run full suite `rvm use ruby-3.1.2 && bundle exec rspec` and fix any regressions — 364 examples, 0 failures
- [x] T025 [P] Review `ScannedDocsController` line count — 8 lines of business logic, within threshold

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately; T002 and T003 are parallel.
- **Foundational (Phase 2)**: Depends on Phase 1 completion. T004–T006 sequential (spec → migrate → run). T007–T008 sequential (spec → impl). T009–T010 parallel with T007–T008.
- **US1 (Phase 3)**: Depends on Phase 2 completion. T011–T012 (specs) parallel, then T013–T015 sequential.
- **US2 (Phase 4)**: Depends on Phase 2 completion (ScannedDoc model). T016–T018 (specs) parallel, T019–T020 parallel, then T021.
- **Polish (Phase 5)**: Depends on Phase 3 + Phase 4 completion.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2. Can be delivered as a standalone MVP.
- **US2 (P2)**: Depends on `ScannedDoc` model (Phase 2) and `OcrJob` enqueue from `Ingestor` (US1 T014). Can be developed in parallel with US1 after Phase 2.

### Parallel Opportunities

Phase 2: T009 (factory) and T010 (resource) in parallel with T007→T008 (model spec + impl).

Phase 3: T011 and T012 (request spec + ingestor spec) in parallel before implementation begins.

Phase 4: T016, T017, T018 (three service/job specs) all in parallel; T019 and T020 (rasterizer + OCR client impl) in parallel before T021.

---

## Parallel Example: Phase 4

```
# Specs — all in parallel:
T016: spec/services/scanned_docs/page_rasterizer_spec.rb
T017: spec/services/scanned_docs/ocr_client_spec.rb
T018: spec/jobs/scanned_docs/ocr_job_spec.rb

# Implementation — T019 and T020 in parallel, then T021:
T019: app/services/scanned_docs/page_rasterizer.rb
T020: app/services/scanned_docs/ocr_client.rb
      ↓ both complete
T021: app/jobs/scanned_docs/ocr_job.rb
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Setup (Dockerfile, credentials, queue config)
2. Phase 2: Foundational (migration, model, factory, resource)
3. Phase 3: US1 (ingestor, controller, routes)
4. **STOP and VALIDATE**: `rvm use ruby-3.1.2 && bundle exec rspec spec/requests/webhook/scanned_docs_spec.rb` + curl smoke test
5. Deploy/demo webhook endpoint

### Full Delivery

1. Complete Setup + Foundational → foundation ready
2. US1 → validates ingest pipeline end-to-end
3. US2 → adds async OCR on top of stored pages
4. Phase 5 Polish → hardening and docs
