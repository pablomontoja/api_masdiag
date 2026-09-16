# Phase 0 Research: Shopify Order Webhook Ingestion

## 1. Shopify webhook authenticity verification

**Decision**: Verify `X-Shopify-Hmac-SHA256` header via
`OpenSSL::HMAC.digest("sha256", webhook_secret, raw_request_body)`, Base64-encoded, compared with
`ActiveSupport::SecurityUtils.secure_compare` against the header value. Reject (401/403, no
processing) on mismatch or missing header. Read the raw body via
`request.body.read` *before* any params parsing, since Shopify's payload must be verified as raw
bytes, not as re-serialized JSON (whitespace/key-order differences would break the HMAC).

**Rationale**: This is Shopify's documented, standard mechanism (a shared secret configured per
webhook subscription in the Shopify admin/API). It requires no new gem — `OpenSSL` and
`ActiveSupport::SecurityUtils` are already used in this codebase's equivalent
`webhook/scanned_docs` controller (Bearer-token constant-time compare). Matches the user's own
statement that they already know which key will sign the payload.

**Alternatives considered**:
- Shopify App Bridge / official `shopify_api` gem webhook verifier — rejected as unnecessary
  weight for a single inbound webhook; the existing codebase pattern (raw HMAC/Bearer compare in
  the controller) is simpler and consistent with `ScannedDocsController`.

## 2. Idempotent delivery storage (the "webhook_deliveries" question)

**Decision**: Build a **feature-scoped** table, not a shared cross-provider `webhook_deliveries`
table as originally sketched. Name it `shopify_order_deliveries`, keyed uniquely on Shopify's
`X-Shopify-Webhook-Id` header (Shopify's own per-delivery idempotency identifier — distinct from
the order ID, since Shopify can redeliver the same logical order-create event with retries that
reuse the webhook-id, but a genuinely edited/recreated order would be a new event). Columns:
`webhook_id` (unique), `shopify_order_id`, `event_type` (fixed to `orders/create` for this
feature, kept as a column for forward-compatibility rather than a hardcoded assumption baked into
the schema), `payload` (JSON, raw body), `status` (enum: `pending`/`processed`/`blocked`/`failed`),
`failure_reason` (text), `processed_at`, timestamps.

**Rationale**: The user's sketch (`provider`, `external_id`, `event_type`, `payload`,
`processed_at`, `failed_at`, `last_error`) is directionally right and the *idempotency + audit*
goals it targets are adopted as hard requirements (FR-003, FR-004, FR-009, FR-010). Two changes
from the sketch:
1. **Scoped, not generic**: A single generic cross-provider `webhook_deliveries` table would mix
   unrelated domains (Shopify orders vs. some future different webhook) behind one schema,
   forcing awkward polymorphic-payload handling and a lowest-common-denominator status model. The
   existing codebase precedent (`ScannedDoc` — a dedicated model per webhook domain, not a shared
   `webhook_deliveries` table) supports a dedicated table per feature. If a second unrelated
   webhook source appears later, a shared *concern* (`Webhookable`/`IdempotentDelivery`) extracted
   from this and `ScannedDoc` would satisfy the constitution's "shared behavior across 3+ models →
   concern" rule better than a premature generic table today (only one other webhook exists;
   threshold not yet crossed).
2. **`status` as enum + separate `blocked` state**: the sketch's `processed_at`/`failed_at` pair
   can't represent "accepted, stored, but blocked pending an unmapped-product fix" (FR-008) as a
   third outcome distinct from a hard failure (FR-012 requires distinguishing these). An integer
   enum column covers all four states from spec's Order Processing Outcome entity cleanly.

**Alternatives considered**:
- Generic `webhook_deliveries(provider, external_id, event_type, payload, ...)` exactly as
  proposed — rejected per above; still noted as a good future extraction point once ≥2 concrete
  webhook domains justify a shared concern (constitution's own threshold rule).
- No dedicated table, rely only on Solid Queue's job dedup — rejected: FR-004/FR-009 require raw
  payload retained independent of job lifecycle (a job can be discarded after retries exhausted;
  the record for manual reprocessing must outlive that).

## 3. Shopify product → `Project` mapping mechanism

**Decision**: A YAML config file (`config/shopify_product_mappings.yml`), keyed by Shopify
`variant_id` (string keys, since Shopify IDs are large integers best treated as opaque strings),
value is an array of `Project.id` integers (supports 1→many). Loaded via a small
`Shopify::ProductMapper` service, memoized per-process (config changes require a deploy/restart —
acceptable per user's explicit choice of config-based over DB-based storage).

**Rationale**: Directly reflects the user's explicit decisions: (a) map by `product_id`/
`variant_id`, not SKU or a metafield lookup; (b) 1 variant → many `Project`s supported; (c)
config-based storage, not a new DB model. This deliberately does **not** extend
`app/models/shop_orders/`: those classes (`ShopOrders::Product#decode_project`) pattern-match on
free-text WordPress product *names* via `case`/regex — a shape that has no equivalent in Shopify's
payload (Shopify gives a stable numeric `variant_id`), so forcing Shopify through that interface
would mean bolting an identifier-based lookup onto a name-based one, coupling two unrelated
mapping strategies. A parallel, independent `Shopify::ProductMapper` avoids that coupling (FR-006)
while still being trivially updatable (FR-007, SC-007) by editing one YAML file — no code change
to the mapping *logic* itself, only the config data.

**Alternatives considered**:
- New ActiveRecord model/table for the mapping — user explicitly declined (chose YAML/config).
  Noted as a natural upgrade path if lab staff need to self-serve mapping changes without a
  deploy; out of scope for this iteration.
- Shopify product metafield carrying the `Project` id directly — rejected because it requires an
  extra Admin API round-trip per order (or relying on the metafield being embedded in the webhook
  payload, which is not guaranteed for `orders/create` line items) and was not the option the user
  chose.

## 4. Async processing split (webhook ack vs. business logic)

**Decision**: Controller does HMAC verify + `Shopify::OrderIngestor.call` (idempotent upsert of
the raw delivery, synchronous, fast) + enqueues `Shopify::ProcessOrderJob` (async) + returns 200
immediately. All product mapping, order blocking/flagging, and (future) sample/test-assignment
creation happen in the job via `Shopify::OrderProcessor`.

**Rationale**: Mirrors the existing, more modern `webhook/scanned_docs` → `ScannedDocs::Ingestor`
→ (commented-out but scaffolded) `ScannedDocs::OcrJob` split already in the codebase, and satisfies
the performance goal (Shopify expects a fast ack) without inventing a new pattern.

**Alternatives considered**:
- Fully synchronous processing in the controller (like the legacy
  `DiagnostykaPrecyzyjna::ShopOrdersController`) — rejected: risks Shopify webhook timeout on
  slower mapping/DB work, and the project's stated direction is away from that older,
  synchronous-everything pattern.

## 5. Sample/test-assignment creation (FR-011) — scope boundary

**Decision**: This plan implements receipt, verification, idempotency, storage, and product→test
*mapping* (User Stories 1–2 in full, User Story 3's diagnostics/reprocessing surface). It stops at
producing a **blocked or mapped-and-ready** `ShopifyOrderDelivery` record with resolved
`Project` ids attached. The actual creation of `Sample`/`ReservedSampleCode` records in the shared
`LabSample` database is flagged as a follow-up decision requiring explicit confirmation, per the
project's standing rule that any LabSample-schema-touching change (and, more broadly, any new
write path into shared tables) gets confirmed with the user before implementation — this feature's
job is not to silently replicate the legacy `DiagnostykaPrecyzyjna::RegShopOrder` inline
stock-reservation logic without that conversation happening first.

**Rationale**: FR-011 requires *traceability* from a processed order to its resulting
sample/test-assignment, but the *mechanism* for creating that assignment (stock-room package
reservation like `RegShopOrder#prepare_rsc`, vs. some new `v1/sample`-style creation path) is a
significant design decision touching shared LabSample tables and warrants its own explicit
sign-off, not an assumption baked in during planning. `Shopify::OrderProcessor` is structured with
a clear extension point (`#assign_sample!` or equivalent) so this can be added as a fast-follow
without restructuring.

**Alternatives considered**:
- Replicate `RegShopOrder#prepare_rsc`'s direct `ReservedSampleCode`/`Package` reservation inline
  — deferred, not rejected outright, pending the explicit LabSample-impact conversation the
  project's own rules require before this is finalized.
