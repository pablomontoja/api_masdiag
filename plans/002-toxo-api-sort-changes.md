# API Sort Support: Required Changes

**Feature**: 002-sortable-tables (companion document)
**Date**: 2026-06-10
**API codebase**: `/home/pswider/rails/api_masdiag`

---

## Summary

This document describes what changes are required in the external API (`api_masdiag`) to support server-side sorting. This can be implemented in parallel with the Rails (toxo) feature — the toxo app uses Ruby-side sort as the default, with a straightforward upgrade path to API-side sort if/when the API is updated.

---

## Performance Assessment

### Is API-side sort worth it?

**Short answer**: Yes for the measurements (results) table; marginal for the samples (orders) table at current data volumes; necessary once data volume grows.

### Measurements table — strong case for API-side sort

The `Toxo::MeasurementPolicy::Scope` builds a **chainable ActiveRecord relation**:

```ruby
# app/policies/toxo/measurement_policy.rb
def resolve
  base = scope.where(ProjectId: Toxo::Constants::TOXO_PROJECT_IDS)
              .joins(sample: :patient)
  if user.is_super_contractor?
    base.where(Patients: { ContractorId: user.institution.contractors.select(:Id) })
  else
    base.where(Patients: { ContractorId: user.Id })
  end
end
```

This means `.order(:AuthorizedAt)` can be appended directly — MySQL executes a single `SELECT ... ORDER BY AuthorizedAt` on the filtered set. The `Measurements.AuthorizedAt` column is **already indexed** (`IX_AuthorizedById` adjacent, and `AuthorizedAt` is present in the schema). Adding an explicit index on `AuthorizedAt` would make this very efficient.

**Benefit**: DB does the sort before transferring rows to Ruby; no in-memory sort in the API process.

### Samples table — moderate case

The `Toxo::SamplePolicy::Scope` resolves via two `pluck` calls to build an `Id IN (...)` list:

```ruby
all_ids = base_ids.pluck(:Id) | wrong_ids.pluck(:Id)
scope.where(Id: all_ids)
```

The final query is `SELECT * FROM Samples WHERE Id IN (id1, id2, ...)`. Appending `.order(:dispatch_date)` here would let MySQL sort using whatever index exists on `dispatch_date`. However, `dispatch_date` currently has **no index** in the schema — so sorting would be a filesort over the id-filtered rows. Still faster than Ruby `sort_by` on the full loaded dataset, but an index migration is also needed for full benefit.

**Sorted columns without indexes on Samples**:
- `dispatch_date` — no index → MySQL filesort on filtered rows
- `AcceptanceDate` — no index → MySQL filesort
- `SampleStatus` — no index → MySQL filesort
- `Lot` — no index (TEXT column) → filesort, cannot be indexed efficiently in MySQL without prefix
- `Code` — **has index** (`IX_Code`) → sort is efficient

---

## Required Changes in `api_masdiag`

### Change 1: Accept sort params in `Toxo::SamplesController#index`

**File**: `app/controllers/toxo/samples_controller.rb`

**Change**:

```ruby
SORTABLE_COLUMNS = {
  "code"            => "Samples.Code",
  "lot"             => "Samples.Lot",
  "dispatch_date"   => "Samples.dispatch_date",
  "acceptance_date" => "Samples.AcceptanceDate",
  "status"          => "Samples.SampleStatus"
}.freeze
ALLOWED_DIRECTIONS = %w[asc desc].freeze

def index
  sort_col = SORTABLE_COLUMNS[params[:sort]]
  sort_dir = ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : nil

  @samples = policy_scope(Toxo::Sample.all)
  @samples = @samples.order(Arel.sql("#{sort_col} #{sort_dir}")) if sort_col && sort_dir

  render json: serialize_samples(@samples)
end
```

**Security note**: The sort column is looked up from a whitelist hash — the value used in the query is the hash value (controlled string), never the raw param. `Arel.sql` is safe here because the string is not user-controlled.

---

### Change 2: Accept sort params in `Toxo::MeasurementsController#index`

**File**: `app/controllers/toxo/measurements_controller.rb`

**Change**:

```ruby
SORTABLE_COLUMNS = {
  "sample_code"  => "Samples.Code",
  "lot"          => "Samples.Lot",
  "authorized_at"=> "Measurements.AuthorizedAt",
  "project"      => "Measurements.ProjectId"
}.freeze
ALLOWED_DIRECTIONS = %w[asc desc].freeze

def index
  sort_col = SORTABLE_COLUMNS[params[:sort]]
  sort_dir = ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : nil

  @measurements = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
  @measurements = @measurements.order(Arel.sql("#{sort_col} #{sort_dir} NULLS LAST")) if sort_col && sort_dir

  render json: @measurements.map { |m| serialize_measurement(m) }
end
```

**Note**: `NULLS LAST` is MySQL 8.0+ syntax. If the DB is MySQL 5.7, use:
```ruby
@measurements = @measurements.order(Arel.sql("#{sort_col} IS NULL, #{sort_col} #{sort_dir}")) if sort_col && sort_dir
```

Also remove the debug `pp` on line 7 (`pp @measurements.map { ... }`) — it's a dev leftover.

---

### Change 3: Add database indexes (migration in `api_masdiag`)

**File**: new migration in `db/migrate/`

```ruby
class AddSortIndexesToSamplesAndMeasurements < ActiveRecord::Migration[8.1]
  def change
    # Samples — columns used in sort ORDER BY
    add_index :Samples, :dispatch_date,   name: "IX_dispatch_date"
    add_index :Samples, :AcceptanceDate,  name: "IX_AcceptanceDate"
    add_index :Samples, :SampleStatus,    name: "IX_SampleStatus_sort"

    # Measurements — AuthorizedAt already present in schema via IX_AuthorizedById-adjacent,
    # but add an explicit index if not present:
    # add_index :Measurements, :AuthorizedAt, name: "IX_AuthorizedAt"
    # (check SHOW INDEX FROM Measurements first — may already exist)
  end
end
```

**Important**: `Lot` is a `TEXT` column — MySQL cannot add a standard B-tree index on TEXT without a prefix length. Since `Lot` values are typically short (e.g. "LOT001"), the sort over the id-filtered set will be a filesort regardless. This is acceptable.

---

### Change 4: Extract sort logic to a concern (optional, clean code)

If both controllers implement the same whitelisting pattern, a shared concern avoids duplication:

**File**: `app/controllers/concerns/toxo/sortable.rb` (new)

```ruby
module Toxo::Sortable
  extend ActiveSupport::Concern

  included do
    # subclass must define SORTABLE_COLUMNS
  end

  ALLOWED_DIRECTIONS = %w[asc desc].freeze

  def apply_sort(relation)
    col = self.class::SORTABLE_COLUMNS[params[:sort]]
    dir = ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : nil
    return relation unless col && dir

    relation.order(Arel.sql("#{col} #{dir} IS NULL, #{col} #{dir}"))
  end
end
```

Then in each controller:
```ruby
include Toxo::Sortable
# ...
@samples = apply_sort(policy_scope(Toxo::Sample.all))
```

---

## Upgrade Path in toxo (Rails App)

Once the API changes above are deployed, update the toxo Rails app:

**`app/models/api_model/base.rb`** — already passes params to `.all(params)`, so no change needed there.

**`app/controllers/samples_controller.rb`** — replace Ruby `sort_by`:
```ruby
# Before (Ruby sort):
@samples = Sample.all
@samples = @samples.sort_by { |s| [s.dispatch_date.nil? ? 1 : 0, s.dispatch_date] } if sort_col == "dispatch_date" && sort_dir == "asc"
# ...

# After (API sort):
@samples = Sample.all(sort: sort_col, direction: sort_dir)
# Remove the sort_by block entirely
```

**`app/controllers/results_controller.rb`** — same pattern.

This is a **backwards-compatible change**: if the API doesn't support sort params yet, passing them does nothing (they're ignored). The Ruby sort acts as an interim fallback until the API is updated.

---

## Recommendation

**Implement Ruby-side sort now** (current plan) — it works immediately with no API deployment dependency. In parallel, apply the 4 changes above to `api_masdiag`. Once those are deployed:

1. Remove the `sort_by` block from `SamplesController#index` and `ResultsController#index`
2. Pass `sort` and `direction` to `Sample.all(...)` / `Measurement.all(...)`

Total upgrade effort in toxo: ~10 lines changed, no test changes needed (tests already verify response order, not the mechanism).
