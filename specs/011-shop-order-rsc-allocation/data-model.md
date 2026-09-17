# Phase 1 Data Model: Shopify Order Kit Allocation

## Entities

### ShopOrder (existing shared LabSample model — extended)

| Field | Type | Notes |
|---|---|---|
| `number` | string, unique | For Shopify orders: `"shopify-#{shopify_order_id}"` (see research.md) |
| `source` | string | **NEW column.** `"wordpress"` (default, backfilled for existing rows) or `"shopify"`. Additive, nullable-with-default migration on a shared table — see plan.md's shared-schema flag. |
| `first_name`, `last_name`, `email`, `phone` | string | Populated from the Shopify order's billing/customer fields (payload already captured on `ShopifyOrderDelivery#payload`) |
| `time_signature` | string | Shopify order's `created_at`/timestamp |
| `total_cost`, `total_cost_with_coupons` | decimal | Sum of kit costs; `total_cost_with_coupons` reflects the existing `price_with_discount` computed in `010-shopify-order-webhook`'s `apply_discount` |
| `coupons` | serialized array | Remains empty for Shopify orders (spec Assumptions — no Shopify coupon model yet) |
| `snapshot_package_ids`, `kits` | serialized array | Populated identically to the WordPress path via existing `after_commit` callbacks (`link_packages`, `update_snapshot_package_ids`) — no behavior change needed |

No change to existing validations (`number` uniqueness, `email` presence) — Shopify orders must supply
both.

### Package / ReservedSampleCode / ReservedTest (existing shared LabSample models — unchanged schema)

One `Package`(via its `ReservedSampleCode`) reserved per kit. Selection query and eligibility rules are
unchanged from `RegShopOrder#prepare_rsc` (now living in `Shopify::RscAllocator`, reused by both
callers — see research.md). Per allocated RSC:

- `IsRetailSale: true`, `InstitutionId: 33` (fixed, per Clarifications)
- One `ReservedTest` created per Project id in the kit's `project_ids`
- `Package#shop_order_id` set via `ShopOrder`'s existing `link_packages` callback (no new code needed —
  reused as-is)
- `Package#comment` and `stock_room_item` (`remaining_quantity: 0, date_out: Time.current`) updated,
  mirroring `stock_room_out`

### ShopifyOrderDelivery (existing app-local model — extended)

| Field | Type | Notes |
|---|---|---|
| `shop_order_id` | bigint, nullable FK | **NEW column** (app-local table, no shared-schema concern). Set once allocation succeeds. |
| `resolved_project_ids` | serialized array | **Kept** for backward-compatible visibility (FR-010) but no longer authoritative — superseded by the linked `ShopOrder`'s kits/packages |
| `status` | enum | Unchanged enum values (`pending`, `processed`, `blocked`, `failed`) — `failed` now also covers "inventory shortfall", not just exceptions |

### Kit (new, non-persisted value object — `Shopify::KitBuilder` output)

```ruby
Kit = Struct.new(:project_ids, keyword_init: false)
```

One `Kit` per unit of line-item quantity. A line item with `quantity: 3` mapped to `project_ids: [18, 3]`
produces 3 separate `Kit.new([18, 3])` instances, not one `Kit` with a quantity field — this directly
satisfies spec Acceptance Scenario 2 (User Story 1) without needing a `quantity` attribute read by
downstream allocation code.

## Relationships

```
ShopifyOrderDelivery --belongs_to--> ShopOrder (optional, nullable until processed)
ShopOrder            --has_many--> Package (existing, dependent: :nullify)
Package              --has_many--> ReservedSampleCode (existing)
ReservedSampleCode    --has_many--> ReservedTest --belongs_to--> Project (existing)
```

## State Transitions (ShopifyOrderDelivery#status)

Unchanged state machine from `010-shopify-order-webhook`, with allocation now happening inside the
`pending → processed` transition:

- `pending → blocked`: any line item unmapped (checked first, before any allocation — FR-007, unchanged)
- `pending → processed`: all line items mapped AND every kit successfully allocated a `Package`/RSC AND
  `ShopOrder` created — now a stronger condition than before (was: mapping alone)
- `pending → failed`: all line items mapped but at least one kit could not be allocated (inventory
  shortfall) — **new** failure path distinct from the existing generic exception-rescue `failed` cases
- `blocked|failed → processed`: via `shopify:reprocess_order_delivery` task, unchanged trigger, now
  re-runs full allocation (FR-008)
