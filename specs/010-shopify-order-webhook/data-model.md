# Phase 1 Data Model: Shopify Order Webhook Ingestion

## New entity: `ShopifyOrderDelivery`

App-local model, **not** a shared `LabSample` table — lives in the `api_masdiag` application
database.

| Field | Type | Notes |
|---|---|---|
| `id` | bigint PK | standard Rails PK |
| `webhook_id` | string | Shopify's `X-Shopify-Webhook-Id` header value; **unique index** — this is the idempotency key (FR-003) |
| `shopify_order_id` | string | Shopify's numeric order id (large — stored as string to avoid integer overflow/precision issues); indexed, not unique (a redelivery of the same order has a different `webhook_id` but the same `shopify_order_id`) |
| `event_type` | string | fixed to `"orders/create"` for this feature; kept as a real column (not hardcoded elsewhere) so a future event type doesn't require a schema change |
| `payload` | json/text | raw request body, exactly as received, verified by HMAC before storage (FR-004) |
| `status` | integer enum | `pending` (0, default) → `processed` (1) \| `blocked` (2) \| `failed` (3) — see State Transitions below |
| `failure_reason` | text, nullable | human-readable cause; populated for `blocked` (e.g., "unmapped variant: 123456") and `failed` (e.g., downstream exception message) — FR-010, FR-012 |
| `unmapped_variant_ids` | json, nullable | list of Shopify variant ids that had no mapping, when `status == blocked`; lets staff fix `config/shopify_product_mappings.yml` and know exactly what to add (FR-008, FR-012) |
| `resolved_project_ids` | json, nullable | flattened list of `Project.id` values resolved across all line items, once `status == processed` (supports FR-011 traceability without yet committing to a `Sample`-linking mechanism — see research.md §5) |
| `processed_at` | datetime, nullable | set when `status` becomes `processed` |
| `created_at` / `updated_at` | datetime | standard Rails timestamps; `created_at` serves as "received at" for SC-001 |

**Indexes**: unique on `webhook_id`; index on `shopify_order_id`; index on `status` (staff
dashboards/queries filtering by `blocked`/`failed`).

**Validations**: `webhook_id` presence + uniqueness (DB-enforced, model-validated for friendly
errors); `payload` presence.

**State Transitions**:

```
pending -> processed   (all line items mapped; FR-005, SC-004)
pending -> blocked     (>=1 line item unmapped; FR-008 — entire order blocked, not partial)
pending -> failed      (unexpected error during processing; FR-012)
blocked -> processed   (reprocessed after config/shopify_product_mappings.yml fixed; FR-009, SC-006)
failed  -> processed   (reprocessed after underlying issue fixed; FR-009, SC-006)
```

No transition ever skips `pending` — every accepted delivery is recorded before processing begins
(FR-004 applies independent of outcome). `blocked` and `failed` are terminal only until manually
reprocessed; there is no automatic retry loop beyond what Solid Queue's own `retry_on` handles for
transient job failures (which itself only moves `pending -> failed`, never fabricates a `blocked`
state — `blocked` is strictly the "unmapped product" outcome, keeping FR-012's distinction sharp).

## Reference-only entity: `Project` (existing, `LabSample`, read-only)

No changes. This feature only reads `Project.id` to validate that configured mapping targets in
`shopify_product_mappings.yml` exist (FR-005's "translate into the lab test(s) it represents"
implies the target must be a real, current `Project`).

## Config-based mapping (not a database entity)

`config/shopify_product_mappings.yml`:

```yaml
# Shopify variant_id (string) => one or more Project.id (LabSample)
"41234567890123": [2]        # single test
"41234567890124": [25, 2]    # bundle: 3-O-metylodopa + witamina D
"41234567890125": [18, 3]    # bundle
```

Loaded and validated (all referenced `Project.id`s exist) once per process by
`Shopify::ProductMapper`; a startup/boot-time check (or a dedicated rake task) SHOULD flag any
configured `Project.id` that no longer exists, to catch drift — implementation detail for
`/speckit-tasks`, not modeled as its own entity since it is pure configuration, not persisted
state.
