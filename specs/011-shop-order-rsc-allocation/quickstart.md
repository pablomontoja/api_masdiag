# Quickstart: Shopify Order Kit Allocation

## Prerequisites

- `010-shopify-order-webhook` already merged and working (webhook ingestion, product mapping).
- At least one `Package`/`ReservedSampleCode` in stock matching the material type/handler for the
  Project ids you intend to test with (see `RegShopOrder#material_type`/`#material_handler` for which
  Project ids route to which bucket).

## Local verification (after implementation)

1. `rvm use 3.4.10 && bin/rails db:migrate` — adds `shop_orders.source` and
   `shopify_order_deliveries.shop_order_id`.
2. Send a signed test payload for a paid order with a mapped, in-stock product (see
   `010-shopify-order-webhook`'s quickstart for the signing steps) — quantity 2 to exercise multi-kit
   allocation. `email` is required (`ShopOrder#email` validation) — Shopify's real `orders/paid`
   payload carries it at the top level, not nested under `billing_address`:
   ```bash
   BODY='{"id":123,"email":"test@example.com","line_items":[{"product_id":15592369881418,"quantity":2}]}'
   ```
3. `rvm use 3.4.10 && bin/rails c`:
   ```ruby
   delivery = ShopifyOrderDelivery.last
   delivery.status            # => "processed"
   delivery.shop_order        # => #<ShopOrder source: "shopify", number: "shopify-123", ...>
   delivery.shop_order.packages.count   # => 2 (one per unit of quantity)
   delivery.shop_order.reserved_sample_codes.flat_map(&:projects).map(&:Id)  # mapped Project ids, once per kit
   ```
4. Send a payload whose mapped Project ids have zero available inventory → confirm `delivery.status ==
   "failed"`, `delivery.shop_order.nil?`, and no `Package`/`ReservedSampleCode` was left reserved
   (`Package.where(shop_order_id: nil).count` unchanged from before the attempt).
5. Send a payload with an unmapped product_id → confirm existing `blocked` behavior is unchanged
   (`delivery.shop_order.nil?`, `unmapped_product_ids` populated) — allocation must not have run at all.

## Running tests

```bash
rvm use 3.4.10 && bundle exec rspec spec/services/shopify/
rvm use 3.4.10 && bundle exec rspec spec/requests/webhook/
rvm use 3.4.10 && bundle exec rspec spec/requests/dp_shop_orders_spec.rb  # regression: RscAllocator extraction must not change WordPress behavior
```
