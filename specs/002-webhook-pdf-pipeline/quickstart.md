# Quickstart: Webhook Scanned PDF Pipeline (Rails)

**Feature**: `002-webhook-pdf-pipeline`
**Date**: 2026-06-02

---

## Prerequisites

### System packages (Docker)

`poppler-utils` (providing `pdftoppm`) is installed via the project Dockerfile — no manual step needed in containerised deployments.

For bare-metal development:

```bash
sudo apt-get install poppler-utils   # provides pdftoppm
```

### llama-server (OCR sidecar)

```bash
# Install llama.cpp (prebuilt release or build from source)
# Then run with a small OCR model:
llama-server -hf ggml-org/GLM-OCR-GGUF \
  --host 127.0.0.1 --port 8080 \
  --temp 0.1

# Or with Dots.OCR (~1.8B, lighter):
llama-server -hf ggml-org/Dots.OCR-GGUF \
  --host 127.0.0.1 --port 8080 \
  --temp 0.1
```

Run under systemd for automatic restarts. The Rails job reads `OCR_ENDPOINT` env var (default: `http://127.0.0.1:8080/v1/chat/completions`).

---

## Rails Setup

### 1. Add the webhook token to credentials

```bash
bin/rails credentials:edit
```

Add:

```yaml
scan_webhook:
  token: <generate with: openssl rand -hex 32>
```

### 2. Run the migration

```bash
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
```

### 3. Configure the OCR queue in Solid Queue

If `ocr` queue isn't already in Solid Queue config, add it:

```yaml
# config/queue.yml (or solid_queue.yml — check existing config)
queues:
  - default
  - ocr        # add this
```

Restart Solid Queue workers after the config change:

```bash
bin/rails solid_queue:start
```

---

## Smoke Test (manual)

### Test the webhook endpoint

```bash
# Generate a test single-page PDF (or use any real one):
# e.g. echo "%PDF-1.4 ..." > /tmp/test-page.pdf

SUM=$(sha256sum /tmp/test-page.pdf | awk '{print $1}')
TOKEN=$(bin/rails runner "puts Rails.application.credentials.dig(:scan_webhook, :token)")

curl -X POST http://localhost:3000/webhook/scanned_docs \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test-page.pdf;type=application/pdf" \
  -F "page_checksum=$SUM" \
  -F "source_filename=test.pdf"
# Expected: {"status":"stored","id":1}

# Re-send the same page (idempotency check):
curl -X POST http://localhost:3000/webhook/scanned_docs \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test-page.pdf;type=application/pdf" \
  -F "page_checksum=$SUM" \
  -F "source_filename=test.pdf"
# Expected: {"status":"duplicate","id":1}

# Test auth failure:
curl -X POST http://localhost:3000/webhook/scanned_docs \
  -H "Authorization: Bearer wrong-token" \
  -F "file=@/tmp/test-page.pdf;type=application/pdf" \
  -F "page_checksum=$SUM" \
  -F "source_filename=test.pdf"
# Expected: 401 {"error":"unauthorized"}
```

### Test OCR round-trip (requires llama-server running)

```bash
# Check a ScannedDoc's status after the job runs:
bin/rails runner "
  doc = ScannedDoc.last
  puts doc.status
  puts doc.markdown.download if doc.markdown.attached?
"
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OCR_ENDPOINT` | `http://127.0.0.1:8080/v1/chat/completions` | llama-server URL |

Set in the process environment for Solid Queue workers if `llama-server` runs on a different host or port.

---

## Key File Locations

| File | Purpose |
|------|---------|
| `app/controllers/webhook/scanned_docs_controller.rb` | Webhook endpoint |
| `app/services/scanned_docs/ingestor.rb` | Ingest + idempotency logic |
| `app/services/scanned_docs/page_rasterizer.rb` | PDF → PNG via pdftoppm |
| `app/services/scanned_docs/ocr_client.rb` | HTTP client for llama-server |
| `app/jobs/scanned_docs/ocr_job.rb` | Async OCR orchestrator |
| `app/models/scanned_doc.rb` | Model + enum + attachments |
| `specs/002-webhook-pdf-pipeline/contracts/webhook_api.md` | Full API contract |

---

## Troubleshooting

### 401 on valid requests
- Verify `scan_webhook: token` is set in credentials for the current `RAILS_ENV`.
- Check that the token in the watcher's env file matches exactly.

### OCR jobs stuck in `ready` status
- Confirm Solid Queue workers are running: `bin/rails solid_queue:start`
- Confirm the `ocr` queue is configured.

### OCR jobs failing with connection errors
- Verify `llama-server` is running: `curl http://127.0.0.1:8080/health`
- Check `OCR_ENDPOINT` env var on the worker process.

### `pdftoppm` not found
- In Docker: verify the Dockerfile includes `poppler-utils` in the `apt-get install` layer and that the image has been rebuilt.
- On bare-metal: `sudo apt-get install poppler-utils`
- Confirm it's on the PATH for the Rails/Solid Queue process user: `which pdftoppm`
