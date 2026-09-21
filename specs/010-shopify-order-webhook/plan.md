# Implementation Plan: Shopify Order Webhook Ingestion

**Branch**: `010-shopify-order-webhook` | **Date**: 2026-09-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-shopify-order-webhook/spec.md`

## Summary

Add a `POST /webhook/shopify/orders_create` endpoint that receives Shopify's `orders/create`
webhook, verifies its HMAC signature, stores the raw payload idempotently keyed by Shopify's
delivery ID, and asynchronously resolves each line item to one or more `Project` records via a
new, independent Shopify-specific mapping mechanism (config-based, not an extension of
`app/models/shop_orders/`). If every line item maps successfully the order is queued for sample
registration; if any line item is unmapped, the whole order is blocked and flagged for manual
resolution. Failed or blocked deliveries remain inspectable and re-triggerable from the stored raw
payload without requiring Shopify to resend anything.

## Technical Context

**Language/Version**: Ruby 3.1.2 (Rails 7 API-only; see `specs/008-ruby-34-upgrade/plan.md` for an
in-flight, unrelated upgrade track — this feature targets the current 3.1.2/Rails 7 baseline and
does not depend on that upgrade landing first)

**Primary Dependencies**: Rails 7 (`ActionController::API`), Solid Queue (background job),
`ActiveSupport::SecurityUtils.secure_compare` for constant-time HMAC comparison (no new gem
required — Shopify HMAC verification is `OpenSSL::HMAC.digest("sha256", secret, body)` +
Base64, both stdlib)

**Storage**: LabSample-adjacent, **but this feature's own tables are new and app-local to
`api_masdiag`**, not shared `LabSample` tables — see Constitution Check / Complexity Tracking.
`Project` (existing, `LabSample`) is read-only from this feature's perspective.

**Testing**: RSpec (request spec for the controller, unit specs for the mapping resolver and the
ingestion service and job), FactoryBot factories, `http_auth_header`/signature-helper pattern
consistent with `spec/support/api_helpers.rb`

**Target Platform**: Linux server (existing `api_masdiag` deployment)

**Project Type**: Single Rails API app (existing `api_masdiag`), new code added under the
established `app/controllers/webhook/`, `app/services/shopify/`, `app/jobs/shopify/`,
`app/models/` structure — no new project/repo.

**Performance Goals**: Webhook endpoint must acknowledge Shopify within Shopify's ~5s webhook
timeout; all mapping/sample-registration work happens asynchronously in a Solid Queue job, not
inline in the request (mirrors `ScannedDocs::Ingestor` + `OcrJob` split).

**Constraints**: Must not modify or extend `app/models/shop_orders/` (FR-006). Must not add any
column/table/index to a shared `LabSample` table without separate explicit user confirmation per
project-wide policy (see Constitution Check) — this feature's own delivery/mapping tables are new,
app-local tables and are exempt from that rule, but any change to `Projects`, `Samples`,
`ReservedSampleCode`, `Package`, etc. is explicitly out of scope here.

**Scale/Scope**: Single Shopify store (per spec Assumptions), low order volume (retail storefront,
not bulk B2B) — no special throughput design needed beyond standard idempotent job processing.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|---|---|---|
| I. Rails Conventions | New code lives under `webhook/` namespace per existing convention; no new namespace invented | PASS |
| II. Service-Object Architecture | Controller only authenticates (HMAC) + delegates to a service; business logic (mapping, order processing) lives in `app/services/shopify/` | PASS |
| III. Test-First | Request spec for controller, unit specs for mapping resolver, ingestion service, and job — written before implementation | PASS (planned) |
| IV. Security & Secrets | Shopify webhook secret stored via Rails credentials, never hardcoded; HMAC verified with constant-time compare, mirroring `ScannedDocsController#authenticate_webhook!` | PASS |
| V. Multi-Tenancy Integrity | This feature does not touch `ApiAccount`/institution-scoped auth (it's Bearer-less HMAC webhook, same class as `webhook/scanned_docs`); the *institution* a Shopify order belongs to is a business-mapping concern (see data-model.md), not an auth concern | PASS — N/A for auth; addressed in data model |
| VI. Layered Architecture | Controller (HTTP+HMAC) → Job (async) → Service (mapping/business logic) → Model (persistence); no logic in controller beyond signature check and enqueue | PASS |

**Shared LabSample database rule** (CLAUDE.md, not the constitution file, but binding): This
feature adds **no** column, table, index, or constraint to any shared `LabSample` table. It reads
`Project` (existing) and, per FR-011, must eventually *write* a sample/test assignment — but the
spec explicitly scopes this feature to receiving, verifying, and mapping the order (User Stories
1–2) plus failure recovery (User Story 3). **Actually creating the `Sample`/`ReservedSampleCode`
records in `LabSample` is a schema-touching, cross-app-impact concern and is called out as a
follow-up decision, not silently implemented — see Assumptions Carried Forward below.**

No violations requiring Complexity Tracking justification.

## Project Structure

### Documentation (this feature)

```text
specs/010-shopify-order-webhook/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
├── contracts/            # Phase 1 output
│   └── webhook-shopify-orders-create.md
└── tasks.md               # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── webhook/
│       └── shopify_orders_controller.rb      # HMAC verify + enqueue only
├── services/
│   └── shopify/
│       ├── order_ingestor.rb                 # idempotent raw-payload persistence (mirrors ScannedDocs::Ingestor)
│       ├── product_mapper.rb                 # Shopify variant_id -> [Project.id] resolution
│       └── order_processor.rb                # orchestrates: map all line items, block-or-proceed per FR-008
├── jobs/
│   └── shopify/
│       └── process_order_job.rb              # async: calls Shopify::OrderProcessor
├── models/
│   └── shopify_order_delivery.rb             # new app-local model (raw payload + processing state)
config/
└── shopify_product_mappings.yml               # Shopify variant_id -> Project id(s), per FR-006/FR-007
db/migrate/
└── <timestamp>_create_shopify_order_deliveries.rb

spec/
├── requests/
│   └── webhook/shopify_orders_controller_spec.rb
├── services/shopify/
│   ├── order_ingestor_spec.rb
│   ├── product_mapper_spec.rb
│   └── order_processor_spec.rb
└── factories/
    └── shopify_order_deliveries.rb
```

**Structure Decision**: Single-project Rails app (existing `api_masdiag`). New code is isolated
under a `Shopify::` module/namespace across controllers, services, jobs, and a dedicated model —
mirroring the existing `ScannedDocs::` vertical slice rather than extending `ShopOrders::` (which
is WordPress-payload-shaped) or the legacy `DiagnostykaPrecyzyjna::` controller (which writes
directly and synchronously to `LabSample` stock tables — an older pattern this feature
deliberately does not repeat, consistent with the project's stated move toward
`api_masdiag`-mediated, auditable order intake).

## Complexity Tracking

*No Constitution Check violations — table intentionally left empty.*
