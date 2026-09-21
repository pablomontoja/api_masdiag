# Feature Specification: Shopify Order Webhook Ingestion

**Feature Branch**: `010-shopify-order-webhook`

**Created**: 2026-09-16

**Status**: Draft

**Input**: User description: "chciałbym przygotować w ramach namespace webhook nowy kontroler do obsługi zamówień wysyłanych z shopify; podaj mi jakich informacji potrzebujesz na temat produktów w moim sklepie shopify aby wykonać to zadanie; mam wiedzę na temat tego jakim kluczem będą podpisane wysyłane informacje; możesz głęboko się zastanowić czy rozsądnym będzie przygotowanie specjalnej tabeli do obsługi webhooków (webhook_deliveries: provider, external_id, event_type, payload, processed_at, failed_at, last_error); ponadto należy już zastanowić się nad tym jak będą mapowane produkty ze sklepu Shopify na odpowiednie badania (Project) w tej aplikacji — obecnie używam kilku modeli do mapowania produktów ze sklepu postawionym na WordPressie (app/models/shop_orders/), ale nie chciałbym rozwijać tej logiki również dla Shopify"

## Clarifications

### Session 2026-09-16

- Q: How should the system handle an order that contains a mix of mappable and unmapped line items? → A: Block the entire order (no test assignment at all) if any line item is unmapped, and flag it for manual resolution.
- Q: Which Shopify order lifecycle events are in scope for this feature? → A: Only order-created; order updates/cancellations are out of scope for now.
- Q: How should discounts/coupons on a Shopify order be handled? → A: Fully replicate the WordPress coupon logic (percentage-based discount applied across line items) for Shopify orders too.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive and record a Shopify order notification (Priority: P1)

When a customer places an order in the Shopify store, Shopify notifies the lab system automatically so that the order can be turned into a registered sample/test without anyone manually re-entering it. Only the order-created event is in scope; order updates and cancellations are not handled by this feature.

**Why this priority**: Without reliable receipt and recording of the incoming order notification, nothing downstream (test assignment, fulfillment, auditing) can happen. This is the foundation the rest of the feature builds on.

**Independent Test**: Send a signed order-created notification from the Shopify store (or a simulated one with a valid signature) and verify the system accepts it, records it as received exactly once, and returns a success acknowledgement.

**Acceptance Scenarios**:

1. **Given** a properly signed order notification from the connected Shopify store, **When** it is received, **Then** the system accepts it and records it as a successfully received order notification.
2. **Given** the same order notification is delivered more than once (which the Shopify platform does by design/retries), **When** it is received again, **Then** the system recognizes the duplicate and does not process the order a second time.
3. **Given** an order notification that fails signature verification, **When** it is received, **Then** the system rejects it and does not record it as a legitimate order.

---

### User Story 2 - Map ordered Shopify products to lab tests (Priority: P1)

Once an order notification is accepted, each purchased product in the order must be translated into the corresponding lab test(s) (`Project`) so the order can be turned into a sample registration and test assignment, the same way orders from the existing WordPress-based store already are.

**Why this priority**: The mapping is the core business value of the integration — without it, an accepted order is just inert data. This must work independently of, and without duplicating, the existing WordPress-store mapping logic.

**Independent Test**: Submit an accepted order containing one or more known Shopify products and verify each line item resolves to the correct lab test(s), including a product that maps to more than one test (bundle/combo product) and a product that maps to none (e.g., a non-test add-on).

**Acceptance Scenarios**:

1. **Given** an order line item for a Shopify product that has a known mapping to a single lab test, **When** the order is processed, **Then** that test is associated with the resulting order/sample.
2. **Given** an order line item for a Shopify product that maps to multiple lab tests (a bundle), **When** the order is processed, **Then** all of the mapped tests are associated with the resulting order/sample.
3. **Given** an order line item for a Shopify product with no configured mapping, **When** the order is processed, **Then** the system blocks the entire order from being turned into a sample/test assignment, flags the unmapped line item, and alerts staff to resolve it — even if other line items on the same order are mappable.
4. **Given** the same Shopify product is later reused for a different test (product/catalog changes over time), **When** the mapping is updated, **Then** future orders use the new mapping without requiring a code change to a per-product list embedded in application logic.

---

### User Story 3 - Recover from and investigate failed order processing (Priority: P2)

When something goes wrong while turning an accepted order notification into a lab test assignment (e.g., an unmapped product, a downstream error), the lab operations team needs to see what failed and why, and be able to have it retried once resolved, without losing the original order data.

**Why this priority**: This directly targets the auditability goal (moving away from silent direct writes) and prevents lost orders, but the system can deliver initial value (Stories 1–2) before this resilience layer is fully built out.

**Independent Test**: Force a processing failure (e.g., feed in an order with an unmapped product) and verify the failure is visible with enough detail to diagnose it, and that reprocessing after a fix succeeds without needing the original notification to be resent.

**Acceptance Scenarios**:

1. **Given** an order notification whose processing fails, **When** the failure occurs, **Then** the system records the failure reason and keeps the original order data available for inspection and reprocessing.
2. **Given** a previously failed order notification, **When** the underlying issue (e.g., missing product mapping) is fixed, **Then** the order can be reprocessed successfully using the stored original data, without Shopify needing to resend it.
3. **Given** several failed order notifications, **When** an operator reviews them, **Then** they can distinguish between different failure reasons (e.g., unmapped product vs. downstream system error).

---

### Edge Cases

- What happens when the same order-created notification is redelivered by Shopify with a different notification ID (e.g., a retry) than a previous delivery of the same order? The system must not create duplicate sample registrations for the same underlying order. Order edits/cancellations made after creation are out of scope (see Clarifications) and are not expected to arrive as separate notifications this feature needs to handle.
- How does the system handle a partially-mappable order (some line items map to tests, others don't)? The entire order is blocked from processing (no partial test assignment) and flagged for manual resolution until every line item is mapped or explicitly excluded.
- How does the system handle an order for a product that was validly mapped at order time but whose mapping is later removed/changed before the order is processed?
- How does the system handle malformed or unexpected payload shapes (e.g., a Shopify API/webhook version change)?
- How does the system handle an order containing a discount/coupon? A percentage-based discount is applied across the order's line items, following the same calculation approach as the existing WordPress store's coupon handling.
- How does the system handle products that are not lab tests at all (e.g., shipping, merchandise, gift cards) and should never map to a `Project`?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an entry point, within the existing machine-to-machine webhook area, dedicated to receiving order-created notifications from the Shopify store. Order update and cancellation events are explicitly out of scope for this feature.
- **FR-002**: System MUST verify the authenticity of every incoming order notification using the signing method associated with the Shopify store before treating it as trustworthy, and MUST reject and discard (without processing) any notification that fails verification.
- **FR-003**: System MUST detect and ignore duplicate deliveries of the same order notification so that the same order is never processed more than once.
- **FR-004**: System MUST retain the raw content of every accepted order notification for later inspection, audit, and reprocessing, independent of whether processing that order succeeds or fails.
- **FR-005**: System MUST translate each purchased product on an incoming order into the lab test(s) it represents, supporting a single product mapping to one or more tests.
- **FR-006**: System MUST NOT extend the existing WordPress-store product-mapping logic (`app/models/shop_orders/`) to also cover Shopify; Shopify product-to-test mapping MUST be maintained as its own independent mechanism.
- **FR-007**: The Shopify product-to-test mapping mechanism MUST allow lab staff to add, change, or remove a product's mapped test(s) as the Shopify catalog evolves, without requiring a matching update to the WordPress-store mapping logic.
- **FR-008**: System MUST clearly flag an order line item for a product that has no configured test mapping, rather than silently ignoring it or guessing, and MUST block the entire order from being turned into a sample/test assignment when any of its line items are unmapped — no partial processing of the mappable line items.
- **FR-009**: System MUST make it possible for lab operations staff to identify, understand the cause of, and trigger reprocessing of an order notification that failed during processing, using the originally retained data.
- **FR-010**: System MUST record, per order notification, at minimum: when it was received, its current processing state (pending/processed/failed), and — for failures — a human-readable reason.
- **FR-011**: System MUST retain, for every successfully processed Shopify order, the resolved lab test(s) (`Project` id(s)) alongside the originating Shopify order identifier, so the order is traceable to what it was mapped to. Creating the actual lab sample/test assignment record (e.g., a registered `Sample` or reserved test code) from that mapping is an explicitly separate follow-on decision, out of scope for this feature, and requires its own confirmation before implementation given its impact on shared `LabSample` write paths.
- **FR-012**: System MUST expose enough information about a failure for staff to distinguish between "unmapped product" failures and other kinds of processing failures (e.g., a downstream system error).
- **FR-013**: System MUST apply any percentage-based discount/coupon on a Shopify order across the order's line items, using the same calculation approach as the existing WordPress store's coupon handling.

### Key Entities *(include if feature involves data)*

- **Shopify Order Notification**: An incoming, signed order-created message from the Shopify store — contains the store's order identifier, purchased line items (product/variant identifiers, quantities, prices), and any discounts applied. Tracked from receipt through processing outcome.
- **Shopify Product-to-Test Mapping**: An association between a Shopify product/variant and one or more lab tests (`Project`), maintained independently of the existing WordPress-store mapping models, and expected to change over time as the Shopify catalog changes.
- **Lab Test (`Project`)**: The existing diagnostic test entity that an order line item is ultimately resolved into; already present in the system and shared across sales channels.
- **Order Processing Outcome**: The result of attempting to turn an accepted order notification into a lab sample/test assignment — success, pending, or failed-with-reason — used for auditing and operator troubleshooting. A `processed` outcome records the resolved test mapping, not a created lab sample/test assignment — that step is a separate, not-yet-scoped follow-on (see FR-011).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every genuine order placed in the Shopify store is recorded by the lab system within seconds of being received, with zero legitimate orders lost.
- **SC-002**: No order is ever processed into a duplicate lab sample/test assignment, even when Shopify redelivers the same order notification multiple times.
- **SC-003**: 100% of order notifications that fail signature verification are rejected and never influence sample/test records.
- **SC-004**: Every purchased product that has a configured mapping is correctly translated into its lab test(s), including products that map to more than one test.
- **SC-005**: 100% of purchased products without a configured mapping are surfaced to staff for review rather than being silently dropped or mis-assigned.
- **SC-006**: A failed order notification can be diagnosed and successfully reprocessed by staff using only information already retained by the system, without asking the customer or Shopify to resend anything.
- **SC-007**: Adding, changing, or removing a Shopify product's test mapping takes effect for new orders without any change to the WordPress-store mapping logic or its models.

## Assumptions

- The Shopify store referenced is a single connected store (not a multi-store setup); multi-store support is out of scope unless stated otherwise.
- "Signed with a key the user already knows" refers to Shopify's standard webhook signing mechanism (a shared secret used to verify the notification's authenticity); the exact secret/credential will be supplied via Rails credentials, consistent with existing key management conventions, and is not part of this specification.
- Order notifications arrive as asynchronous, machine-to-machine "event" deliveries rather than synchronous request/response calls — consistent with how Shopify's platform notifies external systems and with this application's existing `webhook` namespace pattern. Only the order-created event is handled; order updates and cancellations are out of scope for this feature and may be addressed in a future iteration.
- Retaining raw order data and tracking per-notification processing state (received/processed/failed, with failure reason) is treated as a hard requirement (FR-004, FR-010) rather than optional, because it directly serves the organization's broader auditability goal; the exact storage shape is an implementation decision for the planning phase, not this specification.
- The Shopify product-to-test mapping is a genuinely new, independent mechanism (not an extension of `app/models/shop_orders/`), because those models are tightly coupled to WordPress-specific payload shapes (raw form field names, PHP-serialized nested cart data) that do not apply to Shopify's payload structure.
- A single Shopify product/variant can map to more than one lab test (bundle/combo behavior equivalent to today's WordPress "mixed kits"), based on explicit confirmation.
- Discounts/coupons applied to a Shopify order use the same percentage-based, line-item-distributed calculation approach as the existing WordPress store's coupon handling (`ShopOrders::Coupon`); the calculation logic itself may be shared or reimplemented equivalently, but the resulting behavior must match.
- An order containing a mix of mappable and unmapped products is still recorded (per FR-004) but is entirely blocked from becoming a sample/test assignment; the unmapped line item(s) are flagged for manual attention and the whole order awaits resolution before any part of it proceeds.
- Non-test products (shipping, merchandise, gift cards, etc.) are expected to exist in the Shopify catalog and simply have no test mapping configured — they are not an error case by themselves, only line items that fail to match any configured mapping are.
- Creating a lab sample/test assignment from a successfully mapped Shopify order (beyond recording the resolved test mapping itself, per FR-011) is a distinct, not-yet-approved follow-on decision — it would introduce a new write path into shared `LabSample` tables and needs its own explicit confirmation, consistent with this project's standing rule on schema/impact changes to that database.
