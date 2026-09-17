# Phase 0 Research: Shopify Order Kit Allocation

No `NEEDS CLARIFICATION` markers remain in the spec (resolved via `/speckit-clarify`). This document
records the technical decisions needed to move from spec to design.

## Decision: Extract `prepare_rsc`'s query instead of re-deriving it

**Decision**: Move `RegShopOrder#prepare_rsc`'s inventory-selection query (and its `material_type`/
`material_handler` helpers) into a new shared service, `Shopify::RscAllocator` (called from both
`Shopify::OrderProcessor` and, via a thin delegation, `RegShopOrder`).

**Rationale**: The spec's Assumptions section explicitly requires reusing "the same rules" WordPress
orders use — copy-pasting the query into a second file would create two independently-maintained copies
of business-critical inventory logic (which Project ids draw from which material/handler bucket), a
documented Anti-Pattern in the constitution ("Same code in 3+ places" / duplication generally). Since
this is exactly 2 places today, a light extraction (not a full framework) is proportionate.

**Alternatives considered**:
- *Leave `prepare_rsc` where it is and call `DiagnostykaPrecyzyjna::RegShopOrder` from `Shopify::`*:
  rejected — reaching across shop-integration namespaces for reused logic is worse coupling than
  extracting a service, and `RegShopOrder` is stateful (holds `@shop_order`, `@errors`) in ways
  `Shopify::OrderProcessor` doesn't need.
- *Duplicate the query as-is in the new namespace*: rejected per Rationale above — diverges silently
  over time (e.g., a future material-handler rule added to one copy and forgotten in the other).

## Decision: One new service per responsibility — `KitBuilder` and `RscAllocator`

**Decision**: Two new services: `Shopify::KitBuilder#call(line_items)` → returns an array of Kit structs
(`project_ids`, `quantity` exploded to N single-unit kits, matching `ShopOrders::Kit`'s shape minus the
WordPress-specific coupon/product fields this feature doesn't need); `Shopify::RscAllocator#call(project_ids, inst_id:)`
→ reserves and returns one `ReservedSampleCode` or raises/returns nil on shortfall (mirroring
`prepare_rsc`'s nil-on-not-found contract).

**Rationale**: Constitution Principle VI: `Shopify::OrderProcessor#call` doing product-mapping +
kit-grouping + per-kit allocation + `ShopOrder` creation + cost bookkeeping in one method would exceed
the spirit of the 50-line model-method threshold and mixes two distinct concerns (grouping is pure data
transformation; allocation is stateful inventory-reservation with side effects) — splitting them matches
how `RegShopOrder` itself already separates `prepare_ordered_kits` (grouping/looping) from `prepare_rsc`
(allocation).

**Alternatives considered**: A single `Shopify::OrderAllocator` doing both — rejected as it re-creates
the mixed-concern problem `RegShopOrder` already exhibits (loop + query in one place), which this
feature is explicitly trying to not copy uncritically.

## Decision: Transactional rollback boundary

**Decision**: Wrap kit-loop allocation (all `Package`/RSC/`ReservedTest` writes plus `ShopOrder`
creation) in a single `ActiveRecord::Base.transaction`, raising `ActiveRecord::Rollback` the moment any
kit fails to allocate — mirroring `RegShopOrder#call`'s existing `transaction { ...; raise Rollback if
@errors.count > 0 }` pattern exactly.

**Rationale**: Spec FR-006 requires zero partial allocation on shortfall; this is the same guarantee
`RegShopOrder` already provides for WordPress orders, so reusing the identical transaction pattern is
lower-risk than inventing a new one.

**Alternatives considered**: Allocate optimistically and compensate (delete) on failure — rejected,
strictly worse than a DB transaction (window for a concurrent read to see phantom reservations) with no
compensating benefit here since everything is single-request/single-job scoped.

## Decision: `ShopOrder#number` derivation for Shopify orders

**Decision**: `"shopify-#{shopify_order_id}"` (e.g. `"shopify-820982911946154508"`) as the `ShopOrder#number`
value, guaranteeing no collision with WordPress numeric order numbers (`@params["order_number"]`, which
are plain WooCommerce order numbers with no prefix).

**Rationale**: Spec FR-005/edge-case requires a scheme that "cannot collide" with WordPress order
numbers; prefixing with the source is the simplest guarantee, is human-legible in the shared `ShopOrder`
table, and the `shopify_order_id` is already guaranteed unique per Shopify's own id space (enforced today
via `ShopifyOrderDelivery#shopify_order_id`).

**Alternatives considered**: A separate numbering sequence/namespace column instead of a string prefix —
rejected, since the spec's clarified `source` column already carries that distinction structurally; the
`number` field only needs to not collide as a string, which a prefix trivially guarantees without a new
column.

## Decision: `ShopifyOrderDelivery` ↔ `ShopOrder` link

**Decision**: Add `shop_order_id` (nullable FK) directly on `shopify_order_deliveries` (app-local table,
not shared) — `belongs_to :shop_order, optional: true` on `ShopifyOrderDelivery`.

**Rationale**: `shopify_order_deliveries` is app-owned (created in `010-shopify-order-webhook`, not yet
in production), so this is a free, low-risk addition — no shared-table concern applies here (unlike the
`shop_orders.source` column). A direct FK is simpler than deriving the link by matching `ShopOrder#number`
string-parsing at read time.

**Alternatives considered**: Derive the relationship by parsing `ShopOrder#number`'s `"shopify-"` prefix
back to `shopify_order_id` at query time — rejected as fragile/query-unfriendly compared to a real FK.
