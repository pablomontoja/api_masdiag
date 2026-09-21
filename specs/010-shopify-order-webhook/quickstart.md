# Quickstart: Shopify Order Webhook Ingestion

## Prerequisites

- Shopify Admin API access to the connected store, to register the "Order payment" webhook
  subscription (topic `orders/paid`) pointing at
  `https://<api_masdiag-host>/webhook/shopify/orders_create`
- The webhook signing secret, stored via Rails credentials:
  ```bash
  rvm use 3.4.10 && bin/rails credentials:edit
  # add:
  # shopify:
  #   webhook_secret: <secret>
  ```
- At least one entry in `config/shopify_product_mappings.yml` mapping a real Shopify
  `product_id` to an existing `Project.id`, for local testing.

## Local verification (after implementation)

1. `rvm use 3.4.10 && bin/rails db:migrate` — creates `shopify_order_deliveries`.
2. `rvm use 3.4.10 && bin/rails s`
3. Send a signed test payload:
   ```bash
   BODY='{"id":123,"line_items":[{"product_id":41234567890123,"quantity":1}]}'
   SECRET=$(rvm use 3.4.10 --silent && bin/rails runner "print Rails.application.credentials.dig(:shopify, :webhook_secret)")
   SIG=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)
   curl -X POST http://localhost:3000/webhook/shopify/orders_create \
     -H "Content-Type: application/json" \
     -H "X-Shopify-Topic: orders/paid" \
     -H "X-Shopify-Webhook-Id: test-delivery-1" \
     -H "X-Shopify-Hmac-SHA256: $SIG" \
     -d "$BODY"
   ```
   Expect `200 {"status":"accepted"}`.
4. Re-send the exact same request → expect `200 {"status":"duplicate"}` (FR-003).
5. `rvm use 3.4.10 && bin/rails c`:
   ```ruby
   ShopifyOrderDelivery.last.status   # => "processed" once Shopify::ProcessOrderJob runs
   ```
6. Send a payload with an unmapped `product_id` → confirm the resulting delivery has
   `status: "blocked"` and `unmapped_product_ids` populated (FR-008).

## Running tests

```bash
rvm use 3.4.10 && bundle exec rspec spec/requests/webhook/shopify_orders_controller_spec.rb
rvm use 3.4.10 && bundle exec rspec spec/services/shopify/
```
