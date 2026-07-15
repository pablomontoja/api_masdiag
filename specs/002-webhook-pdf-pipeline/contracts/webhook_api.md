# Webhook API Contract: Scanned PDF Ingest

**Version**: 1.0
**Date**: 2026-06-02
**Endpoint**: `POST /webhook/scanned_docs`

---

## Authentication

All requests MUST include an `Authorization` header with a Bearer token:

```
Authorization: Bearer <token>
```

The token is stored in Rails credentials at `scan_webhook: token`. Missing or invalid tokens return `401 Unauthorized`.

---

## Request

### Method & URL

```
POST /webhook/scanned_docs
Content-Type: multipart/form-data
```

### Headers

| Header | Required | Value |
|--------|----------|-------|
| `Authorization` | YES | `Bearer <token>` |
| `Idempotency-Key` | recommended | sha256 of the page PDF (same as `page_checksum`) |
| `Content-Type` | YES | `multipart/form-data` |

### Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | File (PDF) | YES | Single-page PDF. Max 25 MB. Must be valid PDF (starts with `%PDF-`). |
| `page_checksum` | string | YES | sha256 hex digest of the uploaded `file`. Used for idempotency. |
| `source_filename` | string | YES | Original multi-page PDF filename (provenance). |
| `captured_at` | string (ISO 8601) | no | Scanner-side capture timestamp. |
| `document_key` | string | no | sha256 of the source multi-page PDF (optional provenance). |
| `sample_id` | integer | no | ID of an existing `Sample` record to associate with this page. Silently ignored if the ID does not exist. |
| `source` | string | no | Origin identifier. Defaults to `"scan_watcher"`. |

### Example (curl)

```bash
curl -X POST http://rails.lan:3000/webhook/scanned_docs \
  -H "Authorization: Bearer <token>" \
  -H "Idempotency-Key: <sha256>" \
  -F "file=@/tmp/page-1.pdf;type=application/pdf" \
  -F "page_checksum=<sha256>" \
  -F "source_filename=report-2026-06-01.pdf" \
  -F "captured_at=2026-06-01T14:30:00+02:00"
```

---

## Responses

### 202 Accepted — New page stored

```json
{
  "status": "stored",
  "id": 42
}
```

The page PDF has been saved and an OCR job has been enqueued. The `id` is the `ScannedDoc` primary key.

### 202 Accepted — Duplicate (already known page)

```json
{
  "status": "duplicate",
  "id": 17
}
```

A page with the same `page_checksum` already exists. The existing record is unchanged. The `id` refers to the existing `ScannedDoc`.

### 401 Unauthorized

```json
{
  "error": "unauthorized"
}
```

Missing or invalid Bearer token.

### 422 Unprocessable Entity

```json
{
  "error": "<reason>"
}
```

Possible reasons:
- `"no file uploaded"` — `file` field missing
- `"page_checksum required"` — `page_checksum` field missing
- `"file too large"` — file exceeds 25 MB
- `"not a PDF"` — file does not begin with `%PDF-`

---

## Idempotency Semantics

The `page_checksum` field is the idempotency key at the server level. If the same sha256 is submitted twice:
- The second request returns `202 "duplicate"` with the existing record's `id`.
- No new record is created; no new attachment is made.
- The OCR job is NOT re-enqueued for a duplicate.

The optional `Idempotency-Key` header carries the same value for network-layer deduplication (future proxies/gateways).

---

## Error Handling for the Caller

| HTTP Status | Caller action |
|------------|--------------|
| `2xx` | Success — mark page as delivered |
| `401` | Check/rotate WEBHOOK_TOKEN; do not retry automatically |
| `422` | Log + move to FAILED_DIR; do not retry (data error) |
| `5xx` | Retry with exponential backoff |
| `000` (network error) | Retry with exponential backoff |

---

## OCR Lifecycle (async, not part of the webhook contract)

After a `202 "stored"` response, the OCR pipeline runs asynchronously:

1. `ScannedDocs::OcrJob` picks up the `ScannedDoc` (status: `ready`)
2. Sets status → `ocr_pending`
3. Rasterizes `page_pdf` to PNG via `pdftoppm`
4. Sends PNG to local `llama-server` at `OCR_ENDPOINT`
5. Attaches Markdown result as `markdown`; sets status → `transcribed`
6. On error: sets status → `failed`, records `processing_error`, re-raises for Solid Queue retry

The webhook response is not affected by OCR success or failure.
