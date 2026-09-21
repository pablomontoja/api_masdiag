# Feature Specification: Shopify Order Kit Allocation (ShopOrder + ReservedSampleCode)

**Feature Branch**: `011-shop-order-rsc-allocation`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "Fix Shopify order processing to create a real ShopOrder record with per-line-item Package/ReservedSampleCode allocation, mirroring DiagnostykaPrecyzyjna::RegShopOrder#prepare_rsc, instead of storing a flat resolved_project_ids array"

## Context

The current Shopify webhook processing (`Shopify::OrderProcessor`, built in `010-shopify-order-webhook`)
stops at resolving each order line item's Shopify `product_id` to one or more LabSample `Project` ids,
and stores the flattened, de-duplicated result on `ShopifyOrderDelivery#resolved_project_ids` — e.g. an
order with two kits, one mapped to Project 25 and one mapped to Projects [18, 3], is stored as
`[25, 18, 3]`. This loses which Project ids belong together as a single physical kit, and never
allocates the physical `Package`/`ReservedSampleCode` (RSC) inventory that a paid order actually needs
to ship. There is an existing, proven pattern for this exact problem in
`DiagnostykaPrecyzyjna::RegShopOrder` (WordPress-shop order intake): it builds a `ShopOrder` record and,
for each ordered kit, calls `prepare_rsc(project_ids, inst_id)` to reserve one available `Package`/RSC
per kit, tagging it with all of that kit's Project ids via `reserved_tests`, and marking the source
`Package`'s stock room item as taken out of stock.

This feature brings Shopify order processing to parity with that pattern: each Shopify line item
(quantity accounted for) becomes one allocated kit, each kit gets its own `Package`/RSC via the same
`prepare_rsc` inventory-selection logic, and the whole order is recorded as a `ShopOrder`, exactly as
WordPress orders already are today.

## Clarifications

### Session 2026-09-17

- Q: What institution id should be tagged on Shopify-sourced RSC reservations? → A: Reuse the WordPress shop's fixed `inst_id = 33`, and add a `source` column on `shop_orders` to record which intake path (WordPress vs Shopify) created each order.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Paid Shopify order reserves a physical kit per line item (Priority: P1)

As the lab operations team, when a customer's Shopify order is paid and every line item's product maps
to known Projects, I need the system to reserve one physical kit (`Package` + `ReservedSampleCode`) per
line item — not a single flat list of Project ids — so that warehouse stock is actually decremented and
the correct set of Projects is tied to each individual kit that ships.

**Why this priority**: This is the core gap the current implementation leaves open — without it, a paid
Shopify order never actually reserves inventory, so nothing can be shipped or registered from it. This
is the MVP: without this, the feature delivers no operational value beyond bookkeeping.

**Independent Test**: Send a webhook for a paid order with two line items — one quantity-1 item mapped
to a single Project, one quantity-2 item mapped to a bundle of two Projects — and verify a `ShopOrder` is
created with 3 total kits (1 + 2, honoring quantity), each kit resolving to its own `Package`/RSC with
the correct Project ids attached via `reserved_tests`, and each selected `Package`'s stock room item
marked out of stock.

**Acceptance Scenarios**:

1. **Given** a `ShopifyOrderDelivery` whose line items all map to known Projects and for which matching
   `Package` inventory exists, **When** the order is processed, **Then** a `ShopOrder` is created linked
   to that delivery, one `Package`/`ReservedSampleCode` is reserved per unit of line-item quantity, each
   reservation's `reserved_tests` match that line item's mapped Project ids, and the delivery is marked
   `processed`.
2. **Given** a line item with quantity 3, **When** the order is processed, **Then** exactly 3 separate
   kit reservations are made for that line item (not 1 reservation covering quantity 3).
3. **Given** an order with two line items mapped respectively to Project 25 and to Projects [18, 3],
   **When** the order is processed, **Then** the resulting kit records preserve the grouping — Project
   25 alone on one kit, Projects 18 and 3 together on another — rather than a single merged list.

---

### User Story 2 - Insufficient inventory blocks the order for manual resolution (Priority: P2)

As the lab operations team, when a paid Shopify order needs more physical kits of a given
material/handler combination than are currently in stock, I need the delivery to be flagged for manual
attention (not silently partially fulfilled, and not silently lost) so I can restock or intervene before
anything ships incorrectly.

**Why this priority**: Inventory shortfalls are expected to happen occasionally (as they already do for
the WordPress shop) and the existing pattern already handles this by recording an error and rolling back
kit-level DB writes; Shopify orders need the equivalent safety net, but this is secondary to first
getting successful allocation working.

**Independent Test**: Send a webhook for an order whose line items map to valid Projects, but where no
matching `Package` inventory is available for one of the kits, and verify no partial `ShopOrder`/RSC
state is left committed, the delivery is marked for manual attention, and the reason identifies which
kit could not be allocated.

**Acceptance Scenarios**:

1. **Given** an order where every line item maps to known Projects but inventory is insufficient for at
   least one required kit, **When** the order is processed, **Then** no `Package`/`ReservedSampleCode`
   is left reserved for that order, no `ShopOrder` row remains committed, and the delivery is marked
   `failed` with a reason describing the shortfall.
2. **Given** a delivery previously marked `failed` due to a shortfall, **When** inventory becomes
   available and the delivery is reprocessed (existing `shopify:reprocess_order_delivery` task), **Then**
   allocation is retried from the stored payload and can succeed.

---

### User Story 3 - Existing unmapped-product blocking behavior is preserved (Priority: P3)

As the lab operations team, I rely on the existing behavior where an order containing any line item
with no configured Project mapping is blocked entirely (no partial processing), so that this feature
must keep that guarantee even though allocation now also happens.

**Why this priority**: This is a regression guard on already-shipped behavior (`010-shopify-order-webhook`),
not new value, but must not be broken by introducing kit allocation.

**Independent Test**: Send a webhook for an order where one line item has no configured product mapping;
verify the delivery is marked `blocked`, `unmapped_product_ids` is populated, and no `ShopOrder` or kit
allocation is created at all (mapping is checked before any allocation is attempted).

**Acceptance Scenarios**:

1. **Given** an order with at least one unmapped line item, **When** the order is processed, **Then**
   the delivery is marked `blocked` exactly as today, and no `ShopOrder`/`Package`/`ReservedSampleCode`
   records are created or modified.

---

### Edge Cases

- A line item's mapped Project ids belong to a bundle that requires a specific material/handler
  inventory bucket (as `RegShopOrder#material_type`/`#material_handler` already select for the
  WordPress shop) — the same selection rules must apply so Shopify orders don't draw from the wrong
  stock bucket.
- Reprocessing a `failed`/`blocked` delivery must not double-allocate kits if it was partially attempted
  before failing (the transactional rollback in User Story 2 exists precisely to prevent this).
- An order's `ShopOrder#number` must be unique per the existing `ShopOrder` model validation — Shopify's
  order id (already stored as `shopify_order_id`) is the natural unique identifier to reuse, and must be
  distinguishable from WordPress shop order numbers so the two intake paths can never collide.
- A Shopify line item's `quantity` of 0 or missing should be treated as producing zero kit reservations
  for that line item, not an error.
- Money/discount handling already recorded on the delivery's payload (`price_with_discount`, from
  `010-shopify-order-webhook`) should be reflected on the created `ShopOrder`'s cost totals, mirroring
  `RegShopOrder`'s `total_cost`/`total_cost_with_coupons`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST treat each unit of a Shopify line item's quantity as one independently
  allocated kit — a line item with quantity N produces N separate kit allocations, each carrying that
  line item's full set of mapped Project ids.
- **FR-002**: System MUST allocate one available `Package` (via its `ReservedSampleCode`) per kit,
  selected using the same inventory eligibility rules already used for WordPress shop orders (in-stock,
  non-expired within the existing lead time, correct material type/handler for the kit's Project ids),
  and MUST create one `ReservedTest` per Project id on that kit's reservation.
- **FR-003**: System MUST mark each allocated `Package`'s stock room item as taken out of stock and
  annotate it with the originating Shopify order, mirroring the existing WordPress shop order's
  `stock_room_out` behavior.
- **FR-004**: System MUST create exactly one `ShopOrder` record per processed `ShopifyOrderDelivery`,
  linking all of that order's allocated `Package`s to it, and MUST NOT create a `ShopOrder` for an order
  that is blocked (unmapped product) or that fails allocation.
- **FR-005**: System MUST derive the `ShopOrder`'s unique order number from the Shopify order id in a
  way that cannot collide with WordPress shop order numbers, and MUST record `source: "shopify"` on the
  created `ShopOrder` (a new `source` column on `shop_orders`, with existing/WordPress-created rows
  treated as `source: "wordpress"`).
- **FR-006**: If inventory cannot be found for any required kit in the order, system MUST NOT leave any
  partial allocation committed (no `Package`, `ReservedSampleCode`, `ReservedTest`, or `ShopOrder`
  changes persist) and MUST mark the delivery `failed` with a reason identifying the shortfall.
- **FR-007**: System MUST preserve existing behavior: an order with any line item whose product has no
  configured Project mapping is entirely blocked before any allocation is attempted, with no `ShopOrder`
  or kit allocation created.
- **FR-008**: System MUST support reprocessing a `blocked`/`failed` `ShopifyOrderDelivery` from its
  stored payload via the existing `shopify:reprocess_order_delivery` task, re-running full allocation
  including `ShopOrder` creation.
- **FR-009**: System MUST record on the created `ShopOrder` the same cost bookkeeping fields WordPress
  shop orders record (`total_cost`, `total_cost_with_coupons`), computed from the delivery's line items
  and any already-applied discount.
- **FR-010**: The existing `resolved_project_ids` flattened list MAY remain on `ShopifyOrderDelivery` for
  backward-compatible visibility, but MUST NOT be the source of truth for what was actually allocated —
  the `ShopOrder`/`Package`/`ReservedSampleCode`/`ReservedTest` records are authoritative.

### Key Entities

- **ShopOrder**: Existing model; one row per processed order (WordPress or Shopify), linking to the
  `Package`s allocated for its kits, plus customer/cost/coupon bookkeeping. Gains a `source` column
  (e.g. `"wordpress"` / `"shopify"`) to record which intake path created the order, since both now write
  to the same table; `number`'s uniqueness scope covers both intake sources.
- **Package / ReservedSampleCode / ReservedTest**: Existing shared-LabSample models; one `Package`/RSC
  pair is reserved per kit, and one `ReservedTest` per Project id on that kit.
- **Kit** (conceptual, not a persisted model): One unit of line-item quantity plus its resolved Project
  ids — the allocation unit this feature introduces for Shopify orders, mirroring `ShopOrders::Kit` used
  by the WordPress path.
- **ShopifyOrderDelivery**: Existing model from `010-shopify-order-webhook`; gains a link (association or
  foreign key) to the `ShopOrder` created for it once processed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of paid Shopify orders whose line items are fully mapped and have available inventory
  result in a `ShopOrder` with correctly allocated, shippable kits — zero manual data entry required to
  reserve inventory for such orders.
- **SC-002**: An inventory shortfall on any single kit blocks the entire order with zero partial/ghost
  inventory reservations left behind, verified by inventory counts before and after a failed attempt
  being identical.
- **SC-003**: Operations staff can identify, from the delivery record alone, exactly which kit(s) and
  Project grouping(s) an order should have produced, without needing to inspect the raw Shopify payload.

## Assumptions

- The existing `Package`/`ReservedSampleCode` inventory-selection rules (material type/handler by
  Project id, expiry lead time, stock room availability) encoded in `RegShopOrder#prepare_rsc` and its
  helpers are the correct rules to reuse for Shopify orders too — Shopify orders draw from the same
  shared inventory pool as WordPress orders (single `inst_id = 33`, per Clarifications), so no separate
  inventory pool is assumed.
- `Package.product_id` (the Masdiag warehouse `Product`/kit type) is unrelated to Shopify's line-item
  `product_id` (the Shopify catalog product) — the existing `Shopify::ProductMapper` (`product_id` →
  Project ids) remains the only translation layer between the two; this feature does not change that
  mapping, only what happens after Project ids are resolved.
- Discount/coupon handling parity with WordPress shop orders is bookkeeping-only for this feature —
  Shopify orders have no coupon-code model equivalent to `ShopOrders::Coupon`, so `ShopOrder#coupons` is
  expected to remain empty for Shopify-sourced orders unless a follow-on feature adds Shopify discount
  code capture.
- This feature does not change the existing "no `Sample`/registration write path" boundary noted in
  `docs/webhooks/shopify.md` — kit allocation (`Package`/RSC) is inventory reservation, not sample
  registration, and remains distinct from any future registration step.
