# Data Model: Lalen Assign Kit Tests

**Feature**: `004-lalen-assign-kit-tests`
**Date**: 2026-06-24

## No Schema Changes Required

This feature introduces no new database tables or columns. All entities involved already exist.

---

## Entities Involved

### ReservedSampleCode (existing)

The local representation of a kit, identified by `Code` (barcode). Already has:
- `Code` — barcode string (PK equivalent for Lalen lookups)
- `InstitutionId` — scopes to Lalen institutions (IDs in `V1::Common::LALEN_INSTITUTION_IDS`)
- `has_many :reserved_tests` — currently assigned tests

The `assign_tests` action in `Lalen::KitController` already manages this entity. No changes to the model.

### kit_status derivation (for 201 response)

`kit_status` is a **computed string**, not a stored column. `ReservedSampleCode` has no status field — the status is derived at response time:

| Condition | kit_status value |
|-----------|-----------------|
| No `Sample` record exists AND no `reserved_tests` | `"UNREGISTERED"` |
| No `Sample` record exists AND `reserved_tests` present | `"IN_STOCK"` |
| `Sample` record exists | `"ACTIVE"` |

```ruby
kit_status = if @current_rsc.is_registered?
  "ACTIVE"
elsif @current_rsc.reserved_tests.exists?
  "IN_STOCK"
else
  "UNREGISTERED"
end
```

This also defines what "UNREGISTERED" means for FR-003: a `ReservedSampleCode` with no associated `Sample` and no `ReservedTest` records.

### ReservedTest (existing)

Join table between `ReservedSampleCode` and `Project`.
- `reserved_sample_code_id`
- `project_id`

No changes.

### Project (existing)

Represents a diagnostic test.
- `Id` — integer primary key
- `eng_name` — English name (used for display; not the same as `api_key`)

No changes to the model. A mapping constant `LALEN_TEST_API_KEYS` (see below) translates `project_id` → `api_key` slug for the external API.

---

## New Value Object: LalenApi::KitTests

An `ActiveModel`-backed, non-persisted value object that carries and validates the payload sent to the external Lalen portal API. Mirrors `LalenApi::RegisterKit`.

### Attributes

| Attribute | Type    | Validation              |
|-----------|---------|-------------------------|
| `barcode` | String  | presence: true          |
| `tests`   | Array   | presence, length >= 1   |

### JSON serialization

```json
{
  "barcode": "AU1234567",
  "tests": ["vitamin-d", "hba1c"]
}
```

---

## New Mapping Constant: V1::Common::LALEN_TEST_API_KEYS

A strictly 1-to-1 hash mapping Lalen `api_key` slug → local `project_id`, added to `app/lib/v1/common.rb`. Only the 5 tests that are actually used in this integration are included. No duplicate project_ids — the mapping is safely invertible in both directions.

```ruby
# api_key (Lalen portal) => project_id (local)
LALEN_TEST_API_KEYS = {
  "vitamin-d"         => 22,
  "omega-3-basic"     => 21,
  "hba1c"             => 23,
  "homocysteine"      => 12,
  "glutathione-index" => 26
}.freeze
```

**Usage**: `Lalen::KitController#assign_tests` receives `api_keys` (string array) from the partner request, validates them against `LALEN_TEST_API_KEYS.keys`, resolves `project_ids` via `api_keys.map { |k| LALEN_TEST_API_KEYS[k] }`, saves `ReservedTest` records, then enqueues the job with the original `api_keys` array.

---

## Data Flow

```
Lalen::KitController#assign_tests  (MODIFIED — thin, ≤15 lines)
  ├─ looks up ReservedSampleCode by barcode (scoped to LALEN_INSTITUTION_IDS)
  ├─ returns 422 if not found
  └─ delegates to LalenApi::AssignKitTestsService.call(rsc:, api_keys:)
       ├─ on success: json_response 201 { barcode:, kit_status:, tests: }
       └─ on failure: json_response 422 { errors: [...] }

LalenApi::AssignKitTestsService#call  (NEW ApplicationService)
  ├─ validates api_keys against LALEN_TEST_API_KEYS.keys → failure if any unknown
  ├─ validates api_keys non-empty → failure if empty
  ├─ checks UNREGISTERED guard (no sample, reserved_tests present → failure)
  ├─ resolves project_ids: api_keys.map { |k| LALEN_TEST_API_KEYS[k] }
  ├─ transaction: reserved_tests.destroy_all + create ReservedTests by project_id
  ├─ computes kit_status (see derivation table above)
  ├─ enqueues LalenApi::AssignKitTestsJob(barcode, api_keys.uniq)  ← outside transaction
  └─ returns success payload { barcode:, kit_status:, tests: api_keys.uniq }

LalenApi::AssignKitTestsJob#perform(barcode, api_keys)
  ├─ builds LalenApi::KitTests value object
  ├─ validates (presence of barcode, non-empty tests)
  └─ POST /kit_tests via LalenApi::Client.instance.connection
       body: { barcode: barcode, tests: api_keys }
```

**Note**: The current `assign_tests` action accepts integer `test_ids`. The updated action will accept `api_keys` (string array) instead, validating against `LALEN_TEST_API_KEYS.keys`. Confirm with the team whether any existing callers use the old integer format before removing that parameter.
