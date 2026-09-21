# Contract: `POST /webhook/shopify/orders_create`

Machine-to-machine endpoint, `webhook` namespace, called by Shopify's webhook delivery system —
not by any human client or the other apps in the Masdiag ecosystem.

## Authentication

HMAC signature verification (not HTTP Basic, not Bearer — this is Shopify's own scheme):

- Header: `X-Shopify-Hmac-SHA256` — Base64-encoded `HMAC-SHA256(webhook_secret, raw_body)`
- Header: `X-Shopify-Webhook-Id` — Shopify's per-delivery unique id, used as the idempotency key
- Header: `X-Shopify-Topic` — expected value `orders/create`; any other value is rejected (this
  feature only implements the order-created event per Clarifications)
- Header: `X-Shopify-Shop-Domain` — the originating store's `*.myshopify.com` domain (available
  for a future multi-store check; single-store assumption means this is logged, not yet enforced)

A request failing HMAC verification is rejected with `401 Unauthorized` and is **not** persisted
(FR-002 — rejected notifications never influence records).

## Request

- Method/Path: `POST /webhook/shopify/orders_create`
- Content-Type: `application/json`
- Body: Shopify's standard `orders/create` webhook payload (order id, `line_items[]` each with
  `variant_id`, `product_id`, `quantity`, `price`; `discount_applications[]` / `total_discounts`
  for coupon handling per FR-013)

## Response

| Scenario | Status | Body |
|---|---|---|
| Valid signature, new delivery, accepted | `200 OK` | `{ "status": "accepted" }` |
| Valid signature, duplicate `X-Shopify-Webhook-Id` | `200 OK` | `{ "status": "duplicate" }` (FR-003 — Shopify must not see this as a failure worth retrying) |
| Invalid/missing signature | `401 Unauthorized` | `{ "error": "invalid signature" }` |
| Unsupported topic (not `orders/create`) | `422 Unprocessable Content` | `{ "error": "unsupported topic" }` |
| Malformed payload (edge case) | `422 Unprocessable Content` | `{ "error": "..." }` — still logged/captured to Sentry per existing `ExceptionHandler` convention |

Note: the response reflects **acceptance/storage**, not the outcome of asynchronous
mapping/processing (`processed`/`blocked`/`failed`) — that state lives on the
`ShopifyOrderDelivery` record and is surfaced through operator tooling (User Story 3), not the
webhook's synchronous HTTP response, consistent with Shopify expecting a fast ack.

## Idempotency contract

Guaranteed by the unique index on `ShopifyOrderDelivery.webhook_id`. A second delivery with the
same `X-Shopify-Webhook-Id` is detected (via `find_or_create` + rescue
`ActiveRecord::RecordNotUnique`, mirroring `ScannedDocs::Ingestor`'s existing pattern) and short-
circuited to the `duplicate` response without re-enqueuing processing.
