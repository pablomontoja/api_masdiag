# Shopify order webhook

`POST /webhook/shopify/orders_create` receives Shopify's `orders/paid` webhook (the
"Order payment" event) for the connected store. See `specs/010-shopify-order-webhook/`
for the full spec/plan.

## Setup

1. Add the webhook signing secret via `bin/rails credentials:edit`:
   ```yaml
   shopify:
     webhook_secret: <secret from the Shopify webhook subscription>
   ```
2. Register the webhook in Shopify Admin (Settings → Notifications → Webhooks) as
   event **"Order payment"** pointing at `https://<host>/webhook/shopify/orders_create`
   — this sends topic `orders/paid`, which is what the controller expects. Registering
   "Order creation" (`orders/create`) instead will be rejected with 422, since an order
   can be created without ever being paid.
3. Map Shopify product ids to LabSample `Project` ids in
   `config/shopify_product_mappings.yml` (no code change needed to add/change a mapping):
   ```yaml
   "15592369881418": [2]        # single test
   "15655433929034": [25, 2]    # bundle
   ```
   Use the numeric `product_id` from each line item — visible in Shopify Admin's product
   URL (`/products/<product_id>`) — not `variant_id`.

## Behavior

- Signature is verified via HMAC-SHA256; invalid/missing signature → 401, nothing stored.
- Deliveries are idempotent by Shopify's `X-Shopify-Webhook-Id` — redelivery of the same
  webhook never creates a second `ShopifyOrderDelivery` row or re-enqueues processing.
- If any line item's product has no configured mapping, the **entire order is blocked**
  (no partial processing) and flagged on the delivery record (`status: blocked`,
  `unmapped_product_ids`, `failure_reason`) for manual resolution.
- Once every line item is mapped, each unit of line-item quantity is allocated as its own
  physical kit: one `Package`/`ReservedSampleCode` is reserved per kit (same inventory
  selection rules — material type/handler, expiry lead time, stock availability — as the
  WordPress shop order path, via `Shopify::RscAllocator`), tagged with all of that kit's
  mapped `Project` id(s) via `ReservedTest`. The whole order is recorded as a `ShopOrder`
  (`source: "shopify"`, `number: "shopify-<order id>"`), linked from the delivery via
  `ShopifyOrderDelivery#shop_order`.
- If inventory can't be found for any single kit, the **entire order fails** — no partial
  allocation is left behind (all-or-nothing, transactional) — and the delivery is flagged
  (`status: failed`, `failure_reason` naming the unallocated kit's Project ids) for manual
  resolution (restock, then reprocess).
- A `blocked`/`failed` delivery can be reprocessed from its stored payload, after fixing
  the mapping config, restocking inventory, or resolving the underlying issue, without
  Shopify resending anything:
  ```bash
  rails shopify:reprocess_order_delivery[<webhook_id>]
  ```
- This feature does **not** create a `Sample` (registration) in the shared `LabSample`
  database — it stops at reserving the `Package`/`ReservedSampleCode` inventory for each
  kit. Sample registration from an allocated kit is an explicitly separate, not-yet-approved
  follow-on.
