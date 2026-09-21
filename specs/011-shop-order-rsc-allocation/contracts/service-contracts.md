# Internal Service Contracts

No external/HTTP interface changes — `POST /webhook/shopify/orders_create`'s request/response contract
(from `010-shopify-order-webhook`) is unchanged. This feature only changes what happens after that
webhook enqueues `Shopify::ProcessOrderJob`. Contracts below are internal Ruby service interfaces.

## `Shopify::KitBuilder`

```ruby
Shopify::KitBuilder.call(line_items) # => Array<Shopify::KitBuilder::Kit>
```

- **Input**: `line_items` — array of Shopify line-item hashes (as stored in `ShopifyOrderDelivery#payload["line_items"]`), each already known to map to at least one Project id (unmapped-product blocking happens in `Shopify::OrderProcessor` before this is called).
- **Output**: One `Kit` (`project_ids:` array) per unit of quantity. `quantity: 0` or missing → zero kits for that line item (no error).
- **Errors**: None raised — pure data transformation.

## `Shopify::RscAllocator`

```ruby
Shopify::RscAllocator.call(project_ids, inst_id: 33) # => ReservedSampleCode | nil
```

- **Input**: `project_ids` (array of Project ids for one kit), `inst_id` (fixed at 33 for Shopify per Clarifications, but a keyword arg to keep the WordPress caller explicit too).
- **Output**: An updated `ReservedSampleCode` (with `IsRetailSale: true`, `InstitutionId: inst_id`, `reserved_tests` created for each Project id) on success, or `nil` if no eligible `Package`/RSC was found — same nil-on-shortfall contract as today's `RegShopOrder#prepare_rsc`.
- **Side effects**: Persists `ReservedSampleCode#update!` and creates `ReservedTest` rows. Does NOT mark the stock room item out-of-stock — that remains a separate step (`stock_room_out`-equivalent), called by the orchestrating service only after all kits in an order succeed, matching `RegShopOrder`'s ordering (`prepare_rsc` then `stock_room_out` per kit, both inside the same transaction).
- **Errors**: None raised for "not found" (returns nil); underlying validation errors on `update!`/`create` propagate normally (caught by the transaction).

## `Shopify::OrderProcessor` (modified)

```ruby
Shopify::OrderProcessor.call(delivery) # => Shopify::OrderProcessor::Result (existing shape, delivery: ...)
```

- **Behavior change**: After product-mapping succeeds (unchanged), builds kits via `Shopify::KitBuilder`, then inside one `ActiveRecord::Base.transaction`: creates the `ShopOrder` (source: "shopify"), allocates each kit via `Shopify::RscAllocator`, marks each successfully allocated `Package`'s stock room item out-of-stock, and rolls back (`ActiveRecord::Rollback`) if any kit fails to allocate.
- **New failure branch**: if the transaction rolls back due to shortfall, delivery is marked `failed` with a reason naming the unallocated kit's Project ids (not `blocked` — that status remains reserved for the unmapped-product case per FR-007).
- **Unchanged**: unmapped-product detection and `blocked` status path runs first and short-circuits before any of the above (FR-007); discount application (`apply_discount`) unchanged, now feeds `ShopOrder#total_cost_with_coupons`.
