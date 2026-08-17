# Breaking-Change Audit — Execution-Time Re-Verification

**Feature**: 007-rails-72-upgrade | **Verified**: 2026-08-17 | **Against**: branch `007-rails-72-upgrade` @ `d389a4f`
**Tasks**: T005, T006, T007, T008, T009 | **Satisfies**: FR-005, FR-007, FR-012, SC-002

The audit in `spec.md` was a planning snapshot. FR-007 requires re-verification before acting on it. **All 12 findings confirmed unchanged.**

## T005 — Changes with no expected occurrences

| # | Change | Expected | Found | Status |
|---|--------|----------|-------|--------|
| 3 | `params` == `Hash` comparison | 0 | **0** | ✅ confirmed |
| 5 | `Rails.application.secrets` | 0 | **0** | ✅ confirmed |
| 6 | `Migration.check_pending!` | 0 | **0** | ✅ confirmed |
| 9 | `query_constraints` | 0 | **0** | ✅ confirmed |
| 10 | Mailer `args:` → `params:` | 0 | **0** | ✅ confirmed |
| 12 | `alias_attribute` | 0 | **0** | ✅ confirmed |

## T006 — Already-compliant changes

| # | Change | Finding | Status |
|---|--------|---------|--------|
| 2 | `show_exceptions` symbols | Only `config/environments/test.rb:32`, already `:rescuable`. No booleans anywhere. | ✅ compliant |
| 8 | `fixture_path` → `fixture_paths` | Zero active occurrences (the one in `spec/rails_helper.rb` is commented out). Factories only. | ✅ N/A |

## T007 — Cleanup sites (line numbers re-confirmed)

**Change #7 — `serialize` requires `type:`/`coder:`**

| File:line | Current | Action |
|-----------|---------|--------|
| `app/models/key_value_db_store.rb:5` | `serialize :json, ::ActiveRecord::Coders::JSON` — **positional coder** | Migrate to `coder:` keyword (T038) |
| `app/models/shop_order.rb:27,28,29` | already `type: Array` | none |

**Change #4 — `ActiveRecord::Base.connection` deprecated** — 3 sites, all outside production request paths:

| File:line | Context |
|-----------|---------|
| `db/migrate/20260311113835_toxicology_quant_project.rb:229` | historical migration |
| `db/migrate/20260311113835_toxicology_quant_project.rb:233` | historical migration |
| `spec/services/hl7/measurement_importer_spec.rb:57` | spec |

All line numbers match the planning snapshot exactly — no drift.

## T008 — In-transaction enqueue scan (the critical one)

Five files contain both a transaction and a job enqueue. Block boundaries computed to determine whether each enqueue is genuinely inside its transaction:

| File | Transaction | Enqueue | Inside? |
|------|-------------|---------|---------|
| **`app/controllers/fv1/kit_controller.rb`** | **39–46** | **call at 45** → `perform_later` at 68 | **⚠️ YES** |
| `app/controllers/regspec/regspec_sync_controller.rb` | 42–49 | 64 | ✅ no (after) |
| `app/controllers/regspec/samples_controller.rb` | 11–13 | 51 *(commented out)* | ✅ no |
| `app/controllers/toxo/samples/registrations_controller.rb` | opens 22 | 78 | ✅ no (after) |
| `app/controllers/toxo/samples/on_request_measurements_controller.rb` | 18–27 | 29 | ✅ no (after) |

**Confirmed**: `fv1/kit_controller.rb:45` remains the **sole** in-transaction enqueue. Line 45 calls `assign_tests_in_lalen_api`, whose body (line 68) enqueues `LalenApi::AssignKitTestsJob`. The transaction closes at line 46.

## T009 — Newly introduced in-transaction enqueues

**None.** No enqueue site has appeared since the planning snapshot. The E4 decision record in `data-model.md` remains complete with a single entry.

## Verdict

All 12 documented breaking changes re-verified (SC-002). Distribution unchanged from planning:

- **6 not applicable** (#3, #5, #6, #9, #10, #12)
- **2 already compliant** (#2, #8)
- **3 pending cleanup** (#4 ×3 sites, #7 ×1 site) → T038–T040
- **1 pending behavioural fix** (#1, one site) → T015–T022
- **1 low-risk re-check** (#11, built-in `:test` adapter supports `at:`)

**Gate**: PASSED — remediation may proceed.
