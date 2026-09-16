---

description: "Task list for Shopify Order Webhook Ingestion"
---

# Tasks: Shopify Order Webhook Ingestion

**Input**: Design documents from `/specs/010-shopify-order-webhook/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — the project constitution (Principle III, Test-First, NON-NEGOTIABLE)
requires RSpec specs written before implementation code for every layer touched here.

**Organization**: Tasks are grouped by user story (US1, US2, US3 — matching spec.md priorities
P1, P1, P2 respectively) so each can be implemented, tested, and demoed independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

Single Rails project (existing `api_masdiag`). All paths are relative to the repository root.

---

## Phase 1: Setup

**Purpose**: Nothing new to install — no new gem is required (research.md §1). This phase only
registers the mapping config file and Shopify credential slot.

- [ ] T001 Add `shopify.webhook_secret` credential slot via `bin/rails credentials:edit` (manual
      step — document the exact key path in a comment in
      `app/controllers/webhook/shopify_orders_controller.rb` once written; no file to create yet)
- [X] T002 [P] Create `config/shopify_product_mappings.yml` with the example mapping shape from
      data-model.md ("Config-based mapping" section), seeded with one placeholder entry for local
      dev/test

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The one piece of infrastructure every user story depends on — the
`ShopifyOrderDelivery` model/table itself (idempotency key + status enum). Nothing here decides
mapping or blocking behavior; that logic lives in US2.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Create migration `db/migrate/<timestamp>_create_shopify_order_deliveries.rb` per
      data-model.md (`webhook_id` unique index, `shopify_order_id` index, `event_type`, `payload`
      json, `status` integer enum default `pending`, `failure_reason` text,
      `unmapped_variant_ids` json, `resolved_project_ids` json, `processed_at`, timestamps,
      `status` index); run `bin/rails db:migrate` and `bin/rails db:migrate RAILS_ENV=test`
- [X] T004 Create `app/models/shopify_order_delivery.rb` with `status` enum
      (`pending`/`processed`/`blocked`/`failed`), presence validation on `webhook_id` and
      `payload`, uniqueness validation on `webhook_id`
- [X] T005 [P] Create factory `spec/factories/shopify_order_deliveries.rb` (FactoryBot; no
      fixtures per constitution Principle III)
- [X] T006 [P] Add `webhook` namespace route
      `post "shopify/orders_create", to: "shopify_orders#create"` in `config/routes.rb`
      alongside the existing `resources :scanned_docs`

**Checkpoint**: `ShopifyOrderDelivery` persists and round-trips through its four states — user
story implementation can begin.

---

## Phase 3: User Story 1 - Receive and record a Shopify order notification (Priority: P1) 🎯 MVP

**Goal**: A signed `orders/create` webhook is accepted, verified, and idempotently stored exactly
once; an unsigned/invalid one is rejected and never stored.

**Independent Test**: POST a validly-signed payload twice with the same `X-Shopify-Webhook-Id` →
first call creates one `ShopifyOrderDelivery` (`pending`), second call returns duplicate and
creates no second row; POST with a bad signature → 401, zero rows created.

### Tests for User Story 1 ⚠️

- [X] T007 [P] [US1] Request spec
      `spec/requests/webhook/shopify_orders_controller_spec.rb` covering: valid signature → 200
      accepted + row created; duplicate `X-Shopify-Webhook-Id` → 200 duplicate + no second row;
      invalid signature → 401 + no row created; missing `X-Shopify-Hmac-SHA256` header → 401
- [X] T008 [P] [US1] Unit spec `spec/services/shopify/order_ingestor_spec.rb` covering: new
      delivery persists raw payload; same `webhook_id` twice returns the existing record without
      creating a duplicate (including the `ActiveRecord::RecordNotUnique` race path per
      research.md §2/§4)

### Implementation for User Story 1

- [X] T009 [US1] Create `app/services/shopify/order_ingestor.rb` — idempotent
      `find_or_create_by(webhook_id:)` wrapped with rescue on `ActiveRecord::RecordNotUnique`
      (mirrors `ScannedDocs::Ingestor`, per research.md §2), returns a result struct with
      `duplicate?`/`delivery` (depends on T004)
- [X] T010 [US1] Create `app/controllers/webhook/shopify_orders_controller.rb`: reads raw body via
      `request.body.read` before any params parsing, verifies `X-Shopify-Hmac-SHA256` via
      `OpenSSL::HMAC.digest` + `ActiveSupport::SecurityUtils.secure_compare` against
      `Rails.application.credentials.dig(:shopify, :webhook_secret)`, rejects non-`orders/create`
      `X-Shopify-Topic` with 422, calls `Shopify::OrderIngestor`, returns the response shapes from
      `contracts/webhook-shopify-orders-create.md` (depends on T009)
- [X] T011 [US1] Wire `ExceptionHandler`/`Response` concerns into the new controller (same
      concerns used by `Webhook::ScannedDocsController`) so malformed payloads return the
      documented 422 body and get captured to Sentry per existing convention

**Checkpoint**: User Story 1 is fully functional and independently testable — Shopify webhooks
are received, verified, and durably, idempotently recorded, even though nothing is mapped yet.

---

## Phase 4: User Story 2 - Map ordered Shopify products to lab tests (Priority: P1)

**Goal**: Every line item on an accepted delivery is resolved to its `Project`(s) via
`config/shopify_product_mappings.yml`; any unmapped line item blocks the whole order and flags it
per Clarifications (2026-09-16, Q1).

**Independent Test**: Feed a stored `ShopifyOrderDelivery` payload with all variant_ids mapped →
`status` becomes `processed` with `resolved_project_ids` populated; feed one with a mix of mapped
and unmapped variant_ids → `status` becomes `blocked`, `unmapped_variant_ids` lists exactly the
unmapped ones, no partial `resolved_project_ids`.

### Tests for User Story 2 ⚠️

- [X] T012 [P] [US2] Unit spec `spec/services/shopify/product_mapper_spec.rb` covering: known
      `variant_id` → its configured `Project.id` array; `variant_id` mapping to multiple
      `Project`s (bundle, per spec Acceptance Scenario 2); unknown `variant_id` → explicitly
      unmapped (not an exception); config referencing a nonexistent `Project.id` is surfaced
      (per data-model.md's "flag drift" note) rather than silently accepted
- [X] T013 [P] [US2] Unit spec `spec/services/shopify/order_processor_spec.rb` covering: all
      line items mapped → delivery moves to `processed` with correct flattened
      `resolved_project_ids` (dedup across bundle overlaps); one unmapped line item among several
      mapped ones → delivery moves to `blocked`, `failure_reason` and `unmapped_variant_ids` set,
      `resolved_project_ids` stays nil (no partial processing, per FR-008); percentage discount
      present on the payload → applied across line items per FR-013, matching
      `ShopOrders::Coupon`'s calculation shape
- [X] T014 [P] [US2] Unit spec `spec/jobs/shopify/process_order_job_spec.rb` covering: job calls
      `Shopify::OrderProcessor` for the given delivery id; unexpected exception inside the
      processor moves the delivery to `failed` with `failure_reason` set (distinct from
      `blocked`, per FR-012) and re-raises for Solid Queue's `retry_on` to handle

### Implementation for User Story 2

- [X] T015 [P] [US2] Create `app/services/shopify/product_mapper.rb` — loads and memoizes
      `config/shopify_product_mappings.yml` per process, `#project_ids_for(variant_id)` returns
      an array (empty when unmapped), validates at load time that every configured `Project.id`
      exists and logs/raises clearly if not (depends on T002)
- [X] T016 [US2] Create `app/services/shopify/order_processor.rb`: for a given
      `ShopifyOrderDelivery`, resolves every line item's `variant_id` via `Shopify::ProductMapper`;
      if any is unmapped, sets `status: :blocked`, `unmapped_variant_ids`, and a human-readable
      `failure_reason`; otherwise applies the percentage-discount calculation (FR-013, mirroring
      `ShopOrders::Coupon#call`'s percentage-of-total approach) and sets `status: :processed`,
      `resolved_project_ids` (flattened, deduped), `processed_at` (depends on T015, T004)
- [X] T017 [US2] Create `app/jobs/shopify/process_order_job.rb` (`ApplicationJob` subclass,
      `retry_on StandardError, wait: :polynomially_longer, attempts: 5` per constitution
      Development Workflow §4) that loads the `ShopifyOrderDelivery` by id and calls
      `Shopify::OrderProcessor.call`, rescuing to set `status: :failed` +
      `failure_reason: e.message` before re-raising (depends on T016)
- [X] T018 [US2] Update `app/controllers/webhook/shopify_orders_controller.rb` to enqueue
      `Shopify::ProcessOrderJob.perform_later(delivery.id)` after a non-duplicate accept (depends
      on T010, T017)
- [X] T019 [US2] Update request spec `spec/requests/webhook/shopify_orders_controller_spec.rb`
      (from T007) to assert `Shopify::ProcessOrderJob` is enqueued exactly once on accept and not
      re-enqueued on duplicate delivery

**Checkpoint**: User Stories 1 AND 2 both work independently and together — accepted orders are
now fully mapped-or-blocked, matching spec Success Criteria SC-004/SC-005/SC-007.

---

## Phase 5: User Story 3 - Recover from and investigate failed order processing (Priority: P2)

**Goal**: Staff can see why a delivery is `blocked`/`failed` and trigger reprocessing from stored
data, without Shopify resending anything.

**Independent Test**: Take a `blocked` delivery, fix `config/shopify_product_mappings.yml` to
cover the previously-unmapped `variant_id`, trigger reprocessing → delivery moves to `processed`
using only the originally stored `payload`; take a `failed` delivery caused by a raised exception,
fix the underlying issue, trigger reprocessing → delivery moves to `processed`.

### Tests for User Story 3 ⚠️

- [X] T020 [P] [US3] Unit spec `spec/services/shopify/order_processor_spec.rb` (extend from T013)
      covering: reprocessing a `blocked` delivery after the mapping config is fixed succeeds and
      clears `unmapped_variant_ids`/`failure_reason`; reprocessing a `failed` delivery after the
      transient cause is gone succeeds and clears `failure_reason`
- [X] T021 [P] [US3] Rake task spec (or service spec, per chosen implementation) for the
      reprocessing entry point covering: reprocessing a `processed` delivery is a no-op/rejected
      (guards against accidentally reprocessing something already successful)

### Implementation for User Story 3

- [X] T022 [US3] Extend `app/services/shopify/order_processor.rb` (or add a thin wrapper) so it
      is safely re-callable on a `blocked`/`failed` delivery: re-reads the stored `payload`,
      re-resolves mappings, clears stale `failure_reason`/`unmapped_variant_ids` on success
      (depends on T016)
- [X] T023 [US3] Add a reprocessing entry point — `lib/tasks/shopify.rake` task
      `shopify:reprocess_order_delivery[webhook_id]` that finds the delivery by `webhook_id` and
      re-enqueues `Shopify::ProcessOrderJob` for it (guarding against reprocessing an already
      `processed` delivery per T021) — chosen over a new HTTP endpoint since this is an
      operator/console-driven recovery action, not a client-facing API surface (depends on T017)
- [X] T024 [US3] Confirm `ShopifyOrderDelivery.blocked` / `.failed` scopes exist (add if missing)
      so staff can list deliveries needing attention from `bin/rails console`, satisfying FR-012's
      "distinguish between failure kinds" without yet building a dedicated UI (depends on T004)

**Checkpoint**: All three user stories are independently functional — full receive → map/block →
diagnose/reprocess loop works end to end.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation and documentation cleanup that spans all stories.

- [X] T025 [P] Run `quickstart.md` end to end against a local server (curl steps 3–6) and fix any
      discrepancy between the documented curl commands and the actual implementation
- [X] T026 Run `bundle exec rspec spec/requests/webhook/shopify_orders_controller_spec.rb
      spec/services/shopify/ spec/jobs/shopify/` and confirm all pass before considering the
      feature done, per constitution Development Workflow §3
- [X] T027 [P] Verify no controller action exceeds the constitution's 15-line abstraction
      threshold (Principle VI) — `Webhook::ShopifyOrdersController#create` should be
      authenticate-verify-delegate only

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T002's config file is referenced by later
  phases, but the migration/model in T003–T006 has no hard dependency on T001/T002) — BLOCKS all
  user stories
- **User Story 1 (Phase 3)**: Depends on Foundational only
- **User Story 2 (Phase 4)**: Depends on Foundational; **also depends on User Story 1's
  controller (T010) and ingestor (T009)** since it extends the same controller to enqueue the job
  — not fully independent of US1 for that reason, though its mapping/processing logic
  (T012–T017) is unit-testable in isolation without the controller
- **User Story 3 (Phase 5)**: Depends on Foundational and on User Story 2's `OrderProcessor`/
  `ProcessOrderJob` (T016, T017) since reprocessing re-runs the same processing logic
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### Within Each User Story

- Tests written and failing before implementation (constitution Principle III)
- Services before jobs/controllers that call them
- Story complete before moving to next priority

### Parallel Opportunities

- T001/T002 (Setup) in parallel
- T005/T006 (Foundational, different files) in parallel
- T007/T008 (US1 tests, different files) in parallel
- T012/T013/T014 (US2 tests, different files) in parallel
- T015 (US2, `ProductMapper`) can start in parallel with T009–T011 (US1) since it has no
  dependency on the controller/ingestor — only T016 onward needs US1's model (already available
  after Foundational) and, for the controller wiring (T018), US1's controller

---

## Parallel Example: User Story 2

```bash
# Launch all three US2 test files together:
Task: "Unit spec spec/services/shopify/product_mapper_spec.rb"
Task: "Unit spec spec/services/shopify/order_processor_spec.rb"
Task: "Unit spec spec/jobs/shopify/process_order_job_spec.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Shopify can deliver `orders/create` webhooks that are verified and
   durably, idempotently stored — even though nothing is mapped to a `Project` yet
5. Deploy/demo if ready — this alone gives an audit trail of every incoming Shopify order

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. User Story 1 → verified, idempotent receipt (MVP)
3. User Story 2 → mapping and block/proceed logic — this is where the feature's core business
   value (spec's stated priority) actually lands
4. User Story 3 → operator recovery tooling — valuable but not blocking initial production use,
   since a `blocked`/`failed` row is still visible via `bin/rails console` even before T023's rake
   task exists

### Note on scope boundary (research.md §5)

No task in this list creates `Sample`/`ReservedSampleCode` records in the shared `LabSample`
database. `resolved_project_ids` (T016) is where that future work would plug in — flagged
explicitly rather than assumed, per the project's rule that changes touching shared LabSample
write paths need their own explicit confirmation first.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing (constitution Principle III)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
