---

description: "Task list for Shopify Order Kit Allocation (ShopOrder + ReservedSampleCode)"
---

# Tasks: Shopify Order Kit Allocation (ShopOrder + ReservedSampleCode)

**Input**: Design documents from `/specs/011-shop-order-rsc-allocation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/service-contracts.md, quickstart.md

**Tests**: Included and REQUIRED — Constitution Principle III (Test-First, NON-NEGOTIABLE) mandates
RSpec specs before implementation for this project; not optional here.

**Organization**: Tasks are grouped by user story (US1/US2/US3, per spec.md priorities P1/P2/P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

Single Rails project. `app/`, `spec/`, `db/migrate/` at repository root, per plan.md's Project Structure.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Schema changes shared by every story — nothing allocates without these.

- [X] T001 Create migration `db/migrate/<timestamp>_add_source_to_shop_orders.rb` adding a nullable
      `source` string column (default `"wordpress"`) to the **shared LabSample** `shop_orders` table.
      This is additive/backward-compatible (existing readers unaffected), already confirmed by the user
      during `/speckit-clarify` — still call this out explicitly in the migration's file comment as
      touching a shared table used by other apps (`indclients2`, `labpanel`, `order-panel`).
- [X] T002 [P] Create migration `db/migrate/<timestamp>_add_shop_order_id_to_shopify_order_deliveries.rb`
      adding a nullable `shop_order_id` bigint FK (with index) to the app-local `shopify_order_deliveries`
      table. No shared-table concern (table not yet in production).
- [X] T003 Run `rvm use 3.4.10 && bin/rails db:migrate` and
      `RAILS_ENV=test rvm use 3.4.10 && bin/rails db:migrate` to apply T001+T002 to dev and test DBs;
      regenerate `db/schema.rb` and verify only the two new columns/index appear in the diff.
- [X] T004 [P] Update `# == Schema Information` annotation comments at the top of
      `app/models/shop_order.rb` and `app/models/shopify_order_delivery.rb` to reflect the new columns
      (matches this codebase's existing annotate convention — see `app/models/shop_order.rb`'s current
      header).

**Checkpoint**: Schema ready. No behavior changes yet — existing WordPress `ShopOrder` flow and Shopify
webhook flow both still pass their existing specs untouched.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extract the shared inventory-selection logic and add the model associations every user
story's tests/implementation depend on. Per research.md, this MUST happen before US1's allocation logic
is written, since US1 calls into it directly.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [X] T005 [P] Add `belongs_to :shop_order, optional: true` to `app/models/shopify_order_delivery.rb`.
- [X] T006 [P] Add `source` handling to `app/models/shop_order.rb`: no enum needed (plain string column
      per data-model.md), but add a `scope :shopify_sourced, -> { where(source: "shopify") }` and a
      `scope :wordpress_sourced, -> { where(source: "wordpress") }` for operational querying (mirrors
      existing `needs_attention` scope style on `ShopifyOrderDelivery`).
- [X] T007 Write failing spec `spec/services/shopify/rsc_allocator_spec.rb` covering: allocates a
      `ReservedSampleCode` for given `project_ids`/`inst_id` (sets `IsRetailSale: true`,
      `InstitutionId: inst_id`, creates one `ReservedTest` per project id — **explicitly include a case
      with 2+ project_ids and assert one `ReservedTest` row is created per id, not just that
      `reserved_tests` is non-empty**, per FR-002); returns `nil` when no eligible `Package` exists (out
      of stock, expired, wrong material type/handler, or product id 29 exclusion per the existing
      `prepare_rsc` branching); respects the same material_type/material_handler routing rules as
      `RegShopOrder` (reuse the same Project id groupings documented in `reg_shop_order.rb`'s comments:
      dbs/urine material types, OMD/urine handlers). Use FactoryBot, building
      `Package`/`StockRoomItem`/`ReservedSampleCode` fixtures as needed (check `spec/factories/` for
      existing package/stock_room_item factories first).
- [X] T008 Implement `app/services/shopify/rsc_allocator.rb` (`Shopify::RscAllocator < ApplicationService`,
      `call(project_ids, inst_id:)`) by moving `RegShopOrder#prepare_rsc`'s query and the
      `material_type`/`material_handler` private helpers into it verbatim (same logic, no behavior
      change), per contracts/service-contracts.md's `nil`-on-shortfall contract. Make T007 pass.
- [X] T009 Refactor `app/services/diagnostyka_precyzyjna/reg_shop_order.rb#prepare_rsc` to delegate to
      `Shopify::RscAllocator.call(project_ids, inst_id: inst_id)`, keeping its own `@errors <<` message
      on `nil` (WordPress-specific error text stays in `RegShopOrder`, only the query/update logic moves).
      Remove the now-dead `material_type`/`material_handler` private methods from `RegShopOrder`.
- [X] T010 Run `rvm use 3.4.10 && bundle exec rspec spec/requests/dp_shop_orders_spec.rb` to confirm the
      WordPress shop order flow is behavior-identical after the T009 extraction (regression guard called
      out in plan.md and quickstart.md).

**Checkpoint**: `Shopify::RscAllocator` exists, is tested, and `RegShopOrder` already uses it in
production-equivalent behavior. User stories can now build kit allocation on top of it.

---

## Phase 3: User Story 1 - Paid Shopify order reserves a physical kit per line item (Priority: P1) 🎯 MVP

**Goal**: A fully-mapped, in-stock Shopify order produces a real `ShopOrder` with one `Package`/RSC
allocated per unit of line-item quantity, correctly grouped by kit.

**Independent Test**: Per spec.md — webhook a paid order with a quantity-1 single-Project line item and
a quantity-2 two-Project-bundle line item; verify 3 total kit allocations with correct Project groupings.

### Tests for User Story 1 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation.

- [X] T011 [P] [US1] Write failing spec `spec/services/shopify/kit_builder_spec.rb`: a line item with
      quantity N and mapped `project_ids` produces N `Kit` structs each carrying the full `project_ids`
      array (not merged/deduped across kits); quantity 0 or missing produces zero kits; multiple line
      items preserve their separate groupings (Project 25 alone vs. Projects [18, 3] together, per spec
      Acceptance Scenario 3).
- [X] T012 [P] [US1] Update `spec/services/shopify/order_processor_spec.rb` (existing file) — replace/add
      examples asserting: a processed delivery has `shop_order` present, `shop_order.packages.count`
      equals total kit count (sum of quantities), `shop_order.source == "shopify"`,
      `shop_order.number == "shopify-#{shopify_order_id}"`, and each allocated RSC's `reserved_tests`
      match its kit's `project_ids`. Keep existing unmapped-product `blocked` examples unchanged (US3
      regression).
- [X] T013 [P] [US1] Update `spec/requests/webhook/shopify_orders_real_payload_spec.rb` (existing file,
      from `010-shopify-order-webhook`) — the "processes successfully" example must additionally assert
      a `ShopOrder` was created with the expected number of `Package`s (3, matching its 3 mapped line
      items each quantity 1) and that `delivery.shop_order.reserved_sample_codes` map to the expected
      Project ids [18, 3, 25], replacing/augmenting the current `resolved_project_ids` assertion (kept
      per FR-010, no longer sole source of truth).

### Implementation for User Story 1

- [X] T014 [US1] Implement `app/services/shopify/kit_builder.rb` (`Shopify::KitBuilder < ApplicationService`,
      `call(line_items)` → `Array<Kit>`, `Kit = Struct.new(:project_ids)`), exploding each line item's
      `quantity` into that many single-unit `Kit`s carrying the already-resolved `project_ids` for that
      line item. Make T011 pass. (Depends on: none — pure data transformation, no DB.)
- [X] T015 [US1] Modify `app/services/shopify/order_processor.rb#call`: after existing product-mapping
      (unmapped check untouched, still first), call `Shopify::KitBuilder.call(line_items)` directly on
      the original line items (each already known-mapped per contracts/service-contracts.md — do NOT
      re-derive a separate `{product_id => project_ids}` map for this call), then inside
      `ActiveRecord::Base.transaction`, build a `ShopOrder` (customer fields from `@delivery.payload`,
      `source: "shopify"`, `number: "shopify-#{@delivery.shopify_order_id}"`, `email` — see spec
      Assumptions on required `email` presence validation; fall back to a placeholder only if genuinely
      absent from payload, otherwise use the real billing email), and for each `Kit` call
      `Shopify::RscAllocator.call(kit.project_ids, inst_id: 33)`. (Depends on: T014, T008 from Phase 2.)
- [X] T015a [US1] In the same method (T015), compute `total_cost`/`total_cost_with_coupons` on the
      `ShopOrder` from `@delivery.payload["line_items"]` (sum of `price` × quantity, and sum of
      `price_with_discount` × quantity where present, falling back to `price` when no discount was
      applied — mirrors `RegShopOrder#prepare_ordered_kits`'s `kits.sum(&:cost)` /
      `kits.sum(&:cost_with_discount)`), satisfying FR-009. Add an assertion for this to T012's
      `order_processor_spec.rb` updates.
- [X] T016 [US1] In the same transaction block (T015), for every successfully allocated `Package`, mark
      its `stock_room_item` out of stock and set a `comment` referencing the Shopify order — mirror
      `RegShopOrder#stock_room_out`, adapted for the Shopify order/email fields. Link allocated
      `Package`s to the new `ShopOrder` (reuse `ShopOrder`'s existing `package_ids=`/`after_commit
      link_packages` mechanism — set `@shop_order.package_ids` before save, same as `RegShopOrder` does).
- [X] T017 [US1] On success (all kits allocated), set `@delivery.shop_order = shop_order` and call the
      existing `process!(resolved_project_ids)` path (keep `resolved_project_ids` populated per FR-010),
      now additionally persisting the `shop_order_id` association in the same `update!` call.

**Checkpoint**: User Story 1 fully functional and independently testable — run T011–T013 specs green.

---

## Phase 4: User Story 2 - Insufficient inventory blocks the order for manual resolution (Priority: P2)

**Goal**: A kit that can't be allocated rolls back the entire order transaction and marks the delivery
`failed` with a reason, leaving zero partial state.

**Independent Test**: Per spec.md — webhook an order whose Project ids are all mapped but one kit has no
matching inventory; verify no `Package`/RSC/`ShopOrder` persists and the delivery is `failed` with a
shortfall reason.

### Tests for User Story 2 ⚠️

- [X] T018 [P] [US2] Add example to `spec/services/shopify/order_processor_spec.rb`: given a delivery
      whose line items map to Project ids with zero eligible `Package` inventory for one kit, after
      `Shopify::OrderProcessor.call(delivery)` — `delivery.status == "failed"`, `delivery.shop_order`
      is `nil`, `delivery.failure_reason` is present and names the unallocated kit's project ids,
      `ShopOrder.count` unchanged from before the call, and no `Package`/`ReservedSampleCode` was left
      with `IsRetailSale: true` for this order (inventory counts unchanged — verifies transactional
      rollback per FR-006/SC-002).
- [X] T019 [P] [US2] Add example to `spec/requests/webhook/shopify_orders_real_payload_spec.rb`: same
      shortfall scenario at the request-spec level (no `Package` factories created for one of the mapped
      products), asserting the delivery ends up `failed` after `Shopify::OrderProcessor.call(delivery)`.

### Implementation for User Story 2

- [X] T020 [US2] In `app/services/shopify/order_processor.rb`, wrap the T015/T016 transaction body: if
      `Shopify::RscAllocator.call` returns `nil` for any kit, collect the failing kit's `project_ids`,
      `raise ActiveRecord::Rollback` (mirrors `RegShopOrder#call`'s `raise Rollback if @errors.count > 0`
      pattern per research.md), then outside the transaction call a new private `fail!(reason)` method
      (parallel to existing `block!`) that sets `status: :failed`, `failure_reason: "no inventory for
      kit(s) with project_ids: ..."`, `resolved_project_ids: nil`, `unmapped_product_ids: nil`. Make
      T018/T019 pass. (Depends on: T015, T016.)
- [X] T021 [US2] Verify (no new code expected, confirm via test) that `shopify:reprocess_order_delivery`
      rake task (existing, `lib/tasks/shopify.rake`) correctly re-triggers full allocation for a `failed`
      delivery once inventory is added — its existing `next if delivery.processed?` guard already allows
      re-running `blocked`/`failed` deliveries, so this should work unmodified; add a test confirming it
      if none exists at the job/task level.

**Checkpoint**: User Stories 1 AND 2 both work independently — shortfalls no longer leave ghost state.

---

## Phase 5: User Story 3 - Existing unmapped-product blocking behavior is preserved (Priority: P3)

**Goal**: Regression guard — unmapped-product orders are still blocked before any allocation is
attempted, unchanged from `010-shopify-order-webhook`.

**Independent Test**: Per spec.md — webhook an order with one unmapped line item; verify `blocked` status
and that no `ShopOrder`/`Package`/RSC records exist at all.

### Tests for User Story 3 ⚠️

- [X] T022 [P] [US3] Add/confirm example in `spec/services/shopify/order_processor_spec.rb`: given a
      delivery with an unmapped product id, after `Shopify::OrderProcessor.call(delivery)` —
      `delivery.status == "blocked"` (existing assertion), plus new assertions:
      `delivery.shop_order.nil?` and `ShopOrder.count` unchanged (allocation never attempted).

### Implementation for User Story 3

- [X] T023 [US3] Verify (no new code expected) that the existing unmapped-check-then-`block!` early
      return in `app/services/shopify/order_processor.rb` (already runs before any of T015's new
      kit-building/allocation code, since that code is only reached in the `else` branch) still
      short-circuits correctly after T015–T020's changes; fix ordering if T015's edit accidentally moved
      allocation before the unmapped check. Make T022 pass.

**Checkpoint**: All three user stories independently functional and regression-safe.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and end-to-end validation across all three stories.

- [X] T024 [P] Update `docs/webhooks/shopify.md`'s "Behavior" section: replace the note "does **not**
      create a `Sample`/`ReservedSampleCode`" (now false) with a description of kit allocation — one
      `Package`/RSC per unit of line-item quantity, grouped by mapped Project ids, recorded as a
      `ShopOrder` with `source: "shopify"`; keep the still-true "no `Sample`/registration" boundary note
      for the *next* step beyond this feature.
- [X] T025 [P] Update `specs/011-shop-order-rsc-allocation/quickstart.md` if any field names/behavior
      changed during implementation (e.g., actual `fail!`/`failure_reason` wording chosen in T020).
- [X] T026 Run the full suite: `rvm use 3.4.10 && bundle exec rspec` — confirm 0 failures across all
      specs (Shopify + WordPress shop order + everything else), per Constitution Development Workflow
      item 3 (local gate before commit).
- [X] T027 Manually run through `quickstart.md`'s Local verification steps 1–5 against a dev server to
      confirm end-to-end behavior (webhook → allocation → `ShopOrder` visible in console), since this
      touches shared-database writes that are worth a manual sanity check beyond specs alone.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately. T001/T002 parallel; T003 depends on both;
  T004 depends on T003.
- **Foundational (Phase 2)**: Depends on Setup (needs the `shop_order_id`/`source` columns to exist for
  specs to run against real schema). T005/T006 parallel; T007 can be written in parallel with T005/T006
  but T008 (implementation) depends on T007 existing (test-first) and T006 not required for T008 itself.
  T009 depends on T008. T010 depends on T009.
- **User Stories (Phase 3+)**: All depend on Foundational (Phase 2) completion — specifically on
  `Shopify::RscAllocator` (T008) existing.
  - **US1 (P1)**: No dependency on US2/US3. This is the MVP.
  - **US2 (P2)**: Builds on US1's transaction structure (T015/T016) — implement after US1, though its
    tests (T018/T019) can be written in parallel with US1's tests.
  - **US3 (P3)**: Pure regression check on existing behavior — can be verified any time after US1's
    T015 edit exists, but listed last since it's a guard, not new value.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Within Each User Story

- Tests (T011–T013, T018–T019, T022) MUST be written and FAIL before their corresponding implementation
  tasks, per Constitution Principle III.
- `Shopify::KitBuilder` (T014) before `Shopify::OrderProcessor` changes (T015) that call it.
- Allocation (T015/T016) before failure handling (T020) that wraps it.

### Parallel Opportunities

- T001 + T002 (different migration files).
- T005 + T006 (different model files) + T007 (different spec file, no code dependency on T005/T006).
- T011 + T012 + T013 (different spec files, all read-only against not-yet-written implementation).
- T018 + T019 (different spec files).
- T024 + T025 (different doc files).

---

## Parallel Example: User Story 1 tests

```bash
# Launch all three US1 test-writing tasks together (different files):
Task: "Write failing spec spec/services/shopify/kit_builder_spec.rb"
Task: "Update spec/services/shopify/order_processor_spec.rb with ShopOrder/allocation assertions"
Task: "Update spec/requests/webhook/shopify_orders_real_payload_spec.rb with allocation assertions"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (schema).
2. Complete Phase 2: Foundational (`Shopify::RscAllocator` extraction — this is the highest-risk step,
   since it touches `RegShopOrder`'s already-live WordPress behavior; T010's regression run is the gate).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: run `quickstart.md` steps 1–3 against a dev server.
5. Ship — a successful, fully-mapped, in-stock order now reserves real inventory. This alone closes the
   gap the user originally flagged (flat `resolved_project_ids` with no actual reservation).

### Incremental Delivery

1. Setup + Foundational → shared allocator ready, WordPress flow unaffected (T010 green).
2. Add US1 → allocation works for the happy path → deploy.
3. Add US2 → shortfalls fail safely instead of allocating incorrectly/partially → deploy.
4. Add US3 → confirm no regression on the unmapped-product path → deploy.
5. Polish → docs + full-suite + manual check.

---

## Notes

- [P] tasks touch different files with no dependency on each other.
- `Shopify::RscAllocator`'s extraction (T008/T009) is the piece with the widest blast radius — it
  changes a currently-live WordPress code path (`RegShopOrder`), even though behavior is meant to be
  identical. T010's regression spec run is not optional.
- `shop_orders.source` (T001) is a **shared LabSample table** change — already confirmed by the user
  during `/speckit-clarify`, but keep the migration additive (nullable/defaulted) exactly as written so
  no other app sharing that table breaks.
- Commit after each task or logical group, per repository convention observed in prior features
  (`010-shopify-order-webhook`'s history).
