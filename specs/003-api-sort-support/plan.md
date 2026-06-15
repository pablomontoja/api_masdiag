# Implementation Plan: API Server-Side Sort Support

**Branch**: `003-api-sort-support` | **Date**: 2026-06-10 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-api-sort-support/spec.md`

## Summary

Add `sort` and `direction` query parameter support to `GET /toxo/samples` and `GET /toxo/measurements`. Sort column is validated against a per-controller whitelist; direction is restricted to `asc`/`desc`. Shared whitelisting logic lives in a new `Toxo::Sortable` concern. Null values are sorted last using a MariaDB 10.1-compatible `IS NULL` trick. The debug `pp` in `MeasurementsController#index` is also removed.

## Technical Context

**Language/Version**: Ruby 3.1.2 / Rails 7

**Primary Dependencies**: ActiveRecord (Arel.sql for safe raw ORDER BY), Pundit (policy_scope)

**Storage**: MariaDB 10.1 — `NULLS LAST` syntax NOT supported; use `ORDER BY col IS NULL, col dir`

**Testing**: RSpec — request specs in `spec/requests/toxo/`

**Target Platform**: Linux server (API-only Rails app)

**Project Type**: Web service (API-only)

**Performance Goals**: Sort pushed to DB; no in-memory sort in Ruby

**Constraints**: Column values used in ORDER BY must come from a controlled whitelist, never from raw user input. MariaDB 10.1 compatibility required.

**Scale/Scope**: Two controller actions, one new concern, extended request specs

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Rails Conventions | ✅ PASS | Concern in `app/controllers/concerns/toxo/`, controllers stay thin |
| II. Service-Object Architecture | ✅ PASS | Sort param parsing is controller-level request handling (<15 lines), no business logic — concern is appropriate, no service object needed |
| III. Test-First | ✅ PASS | Request specs written before implementation |
| IV. Security & Secrets | ✅ PASS | Whitelist hash prevents SQL injection; `Arel.sql` receives only controlled strings |
| V. Multi-Tenancy Integrity | ✅ PASS | `policy_scope` applied before sort; sort does not bypass scoping |
| VI. Layered Architecture | ✅ PASS | Sort logic is HTTP/controller-layer concern; concern extraction justified (shared by 2+ controllers) |

## Project Structure

### Documentation (this feature)

```text
specs/003-api-sort-support/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
app/controllers/
├── concerns/
│   └── toxo/
│       └── sortable.rb          # NEW — shared sort param handling
└── toxo/
    ├── samples_controller.rb    # MODIFIED — include Toxo::Sortable, apply_sort
    └── measurements_controller.rb  # MODIFIED — include Toxo::Sortable, apply_sort, remove pp

spec/requests/toxo/
├── samples_spec.rb              # MODIFIED — add sort scenarios
└── measurements_spec.rb         # NEW — add sort scenarios (and basic coverage)
```

**Structure Decision**: Single-project Rails API. Concern placed in `app/controllers/concerns/toxo/` following the existing pattern for `lalen_check.rb`, `masdiag_check.rb`, etc.

## Phase 0: Research

See [research.md](research.md).

## Phase 1: Design

### Toxo::Sortable Concern

```ruby
# app/controllers/concerns/toxo/sortable.rb
module Toxo
  module Sortable
    extend ActiveSupport::Concern

    ALLOWED_DIRECTIONS = %w[asc desc].freeze

    def apply_sort(relation)
      col = self.class::SORTABLE_COLUMNS[params[:sort]]
      dir = ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : nil
      return relation unless col && dir

      # MariaDB 10.1: no NULLS LAST syntax — use IS NULL sentinel
      relation.order(Arel.sql("#{col} IS NULL, #{col} #{dir}"))
    end
  end
end
```

### Samples Controller Changes

```ruby
# app/controllers/toxo/samples_controller.rb
class Toxo::SamplesController < Toxo::BaseController
  include Toxo::Sortable

  SORTABLE_COLUMNS = {
    "code"            => "Samples.Code",
    "lot"             => "Samples.Lot",
    "dispatch_date"   => "Samples.dispatch_date",
    "acceptance_date" => "Samples.AcceptanceDate",
    "status"          => "Samples.SampleStatus"
  }.freeze

  def index
    @samples = apply_sort(policy_scope(Toxo::Sample.all))
    render json: serialize_samples(@samples)
  end
  # ... rest unchanged
end
```

### Measurements Controller Changes

```ruby
# app/controllers/toxo/measurements_controller.rb
class Toxo::MeasurementsController < Toxo::BaseController
  include Toxo::Sortable

  SORTABLE_COLUMNS = {
    "sample_code"   => "Samples.Code",
    "lot"           => "Samples.Lot",
    "authorized_at" => "Measurements.AuthorizedAt",
    "project"       => "Measurements.ProjectId"
  }.freeze

  def index
    @measurements = apply_sort(
      policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
    )
    # pp line removed
    render json: @measurements.map { |m| serialize_measurement(m) }
  end
  # ... rest unchanged
end
```

### Null Sort Behavior (MariaDB 10.1)

`ORDER BY col IS NULL, col dir` produces:
- `asc`: non-nulls first in ascending order, then nulls
- `desc`: non-nulls first in descending order, then nulls

This matches the expected "nulls last" behavior for both directions.

### Security Note

The string passed to `Arel.sql` is constructed from:
1. `self.class::SORTABLE_COLUMNS[params[:sort]]` — a controlled hash value, never the raw param
2. `dir` — restricted to `"asc"` or `"desc"` by the `ALLOWED_DIRECTIONS` guard

The raw `params[:sort]` and `params[:direction]` values are never interpolated into SQL.
