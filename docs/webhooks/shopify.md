# Shopify order webhook

`POST /webhook/shopify/orders_create` receives Shopify's `orders/create` webhook for the
connected store. See `specs/010-shopify-order-webhook/` for the full spec/plan.

## Setup

1. Add the webhook signing secret via `bin/rails credentials:edit`:
   ```yaml
   shopify:
     webhook_secret: <secret from the Shopify webhook subscription>
   ```
2. Register the webhook in Shopify Admin pointing at
   `https://<host>/webhook/shopify/orders_create`, topic `orders/create`.
3. Map Shopify variant ids to LabSample `Project` ids in
   `config/shopify_product_mappings.yml` (no code change needed to add/change a mapping):
   ```yaml
   "41234567890123": [2]        # single test
   "41234567890124": [25, 2]    # bundle
   ```

## Behavior

- Signature is verified via HMAC-SHA256; invalid/missing signature → 401, nothing stored.
- Deliveries are idempotent by Shopify's `X-Shopify-Webhook-Id` — redelivery of the same
  webhook never creates a second `ShopifyOrderDelivery` row or re-enqueues processing.
- If any line item's variant has no configured mapping, the **entire order is blocked**
  (no partial processing) and flagged on the delivery record (`status: blocked`,
  `unmapped_variant_ids`, `failure_reason`) for manual resolution.
- A `blocked`/`failed` delivery can be reprocessed from its stored payload, after fixing
  the mapping config or the underlying issue, without Shopify resending anything:
  ```bash
  rails shopify:reprocess_order_delivery[<webhook_id>]
  ```
- This feature does **not** create a `Sample`/`ReservedSampleCode` in the shared
  `LabSample` database — it stops at resolving and recording the mapped `Project` id(s) on
  the delivery. That write path is an explicitly separate, not-yet-approved follow-on.
