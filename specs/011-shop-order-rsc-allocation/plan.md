# Implementation Plan: Shopify Order Kit Allocation (ShopOrder + ReservedSampleCode)

**Branch**: `011-shop-order-rsc-allocation` | **Date**: 2026-09-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-shop-order-rsc-allocation/spec.md`

## Summary

`Shopify::OrderProcessor` currently only resolves each order line item's Shopify `product_id` to
LabSample `Project` ids and stores a flat, deduplicated `resolved_project_ids` array on
`ShopifyOrderDelivery` — it never reserves physical inventory. This feature makes it allocate real
inventory: each unit of line-item quantity becomes one "kit" (a group of Project ids), and each kit gets
its own `Package`/`ReservedSampleCode` reservation via the same selection logic
`DiagnostykaPrecyzyjna::RegShopOrder#prepare_rsc` already uses for WordPress shop orders. The whole order
is recorded as a `ShopOrder`, reusing the existing shared model, with `inst_id = 33` (same institution as
WordPress orders) and a new `source` column distinguishing `"shopify"` from `"wordpress"` orders. A
shortfall in any single kit's inventory rolls back the entire order (transactional, matching
`RegShopOrder`'s pattern) and marks the delivery `failed`; the existing unmapped-product `blocked` path
is unchanged and still short-circuits before any allocation is attempted.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.0 (API-only)

**Primary Dependencies**: ActiveRecord (multi-database: LabSample primary + Solid Queue), existing
`ApplicationService` base class, Solid Queue for `Shopify::ProcessOrderJob`

**Storage**: MySQL, shared `LabSample` database — this feature's writes touch `shop_orders`, `packages`,
`ReservedSampleCodes`, `reserved_tests` (all existing shared tables) plus the app-local
`shopify_order_deliveries` table

**Testing**: RSpec + FactoryBot (no fixtures), request specs for the webhook endpoint, service specs for
`Shopify::OrderProcessor`

**Target Platform**: Linux server (existing Rails API deployment)

**Project Type**: Single Rails API-only application (existing `api_masdiag`)

**Performance Goals**: N/A beyond existing webhook processing — allocation runs inside the existing
async `Shopify::ProcessOrderJob`, not the synchronous webhook request

**Constraints**: MUST reuse `RegShopOrder#prepare_rsc`'s exact inventory-selection query (material
type/handler, expiry lead time, stock room availability) rather than re-deriving it, per spec Assumptions

**Scale/Scope**: Single Shopify store, low order volume (parity feature, not a new integration)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Rails Conventions**: PASS. No new namespace; stays within existing `Shopify::` service namespace
  and existing `webhook/` controller namespace.
- **II. Service-Object Architecture**: PASS. All new allocation logic goes into `Shopify::OrderProcessor`
  (already a service) plus new extracted service objects (kit allocation, RSC selection) — no logic
  added to controllers or models beyond associations.
- **III. Test-First**: PASS (plan commits to it). RSpec specs for the new/changed services and the
  `ShopifyOrderDelivery` → `ShopOrder` association precede implementation.
- **IV. Security & Secrets**: PASS. No new secrets; no change to webhook signature verification.
- **V. Multi-Tenancy Integrity**: N/A/PASS. `webhook/` namespace uses Bearer/HMAC auth, not
  institution-scoped `ApiAccount` access — allocation writes a fixed `InstitutionId` (33), matching the
  existing WordPress shop order pattern; this is not a cross-tenant *read* path.
- **VI. Layered Architecture**: PASS. Kit grouping and RSC selection are "complex business logic" →
  service objects; no query object needed since `prepare_rsc`'s query is reused/extracted, not
  redesigned as a 3+-join report.

**Shared-database schema change flag** (project-specific rule, not a constitution principle, but
CLAUDE.md ABSOLUTE RULES apply): `shop_orders` and `ReservedSampleCodes`/`packages` are shared
`LabSample` tables used by other apps (`indclients2`, `labpanel`, `order-panel`, etc.), not owned solely
by `api_masdiag`. The spec's clarified decision to add a `source` column to `shop_orders` is a schema
change to a shared table and **requires explicit user confirmation before the migration is written**,
per CLAUDE.md — the user already confirmed this specific column during `/speckit-clarify`
("add source column in shop_orders table"), so this gate is satisfied, but the actual migration task
in `/speckit-tasks` MUST still surface it plainly as a shared-table change (nullable, additive,
non-breaking: existing readers of `shop_orders` that don't know about `source` are unaffected).

No violations requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/011-shop-order-rsc-allocation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal service contracts, no external API added)
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
app/
├── services/
│   └── shopify/
│       ├── order_processor.rb       # MODIFIED — orchestrates kit build + allocation + ShopOrder creation
│       ├── order_ingestor.rb        # unchanged
│       ├── product_mapper.rb        # unchanged
│       ├── kit_builder.rb           # NEW — groups line items (with quantity) into Kit structs, mirrors ShopOrders::Kit
│       └── rsc_allocator.rb         # NEW — wraps RegShopOrder#prepare_rsc's selection query for one kit, extracted for reuse
├── models/
│   ├── shopify_order_delivery.rb    # MODIFIED — belongs_to :shop_order, optional: true
│   └── shop_order.rb                # MODIFIED — new `source` enum/string column, scope by source
├── jobs/
│   └── shopify/
│       └── process_order_job.rb     # unchanged (calls Shopify::OrderProcessor as today)
db/migrate/
├── <timestamp>_add_shop_order_id_to_shopify_order_deliveries.rb   # NEW
└── <timestamp>_add_source_to_shop_orders.rb                        # NEW (shared-table, additive/nullable)

spec/
├── services/shopify/
│   ├── order_processor_spec.rb      # MODIFIED — allocation assertions replace flat resolved_project_ids-only assertions
│   ├── kit_builder_spec.rb          # NEW
│   └── rsc_allocator_spec.rb        # NEW
└── requests/webhook/
    └── shopify_orders_real_payload_spec.rb   # MODIFIED — assert ShopOrder + Package/RSC allocation, not just resolved_project_ids
```

**Structure Decision**: Existing single Rails API project structure is reused as-is. New allocation
logic is added as two new service objects under `app/services/shopify/` (kit grouping, RSC allocation)
rather than growing `Shopify::OrderProcessor` past its current size, per Constitution Principle VI's
extraction threshold. `RegShopOrder#prepare_rsc`'s inventory-selection query is extracted into the new
`Shopify::RscAllocator` so it is not duplicated between `DiagnostykaPrecyzyjna::RegShopOrder` and this
feature — `RegShopOrder` will be updated to delegate to it (kept behavior-identical, covered by its
existing specs) rather than leaving two divergent copies of the same query, which the "Anti-Patterns"
table's stringly-typed/duplication concerns argue against.

## Complexity Tracking

No Constitution Check violations. This section is not applicable.
