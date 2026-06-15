# Research: API Server-Side Sort Support

**Feature**: 003-api-sort-support | **Date**: 2026-06-10

## Decision 1: SQL NULL handling for sort order

**Decision**: Use `ORDER BY col IS NULL, col dir` (MariaDB 10.1 compatible)

**Rationale**: MariaDB 10.1 does not support the `NULLS LAST` / `NULLS FIRST` SQL clause introduced in MySQL 8.0. The boolean expression `col IS NULL` evaluates to 0 (false) for non-null rows and 1 (true) for null rows. Because `ORDER BY` treats 0 < 1, non-null rows sort before null rows regardless of the primary sort direction. This achieves "nulls last" behavior on both `asc` and `desc` sorts.

**Alternatives considered**:
- `ORDER BY col ASC NULLS LAST` — MySQL 8.0+ / PostgreSQL only, not supported on MariaDB 10.1
- `COALESCE(col, '9999-12-31')` — date-specific hack, not generalizable, fragile
- Ruby-side nil guard (`sort_by { |r| [r.col.nil? ? 1 : 0, r.col] }`) — defeated the purpose of DB-side sort

## Decision 2: Concern vs. inline whitelist per controller

**Decision**: Extract to `Toxo::Sortable` concern in `app/controllers/concerns/toxo/`

**Rationale**: Both `SamplesController` and `MeasurementsController` need identical parameter parsing and direction validation logic. Duplicating it would cross the constitution's "same code in 2+ places → extract" threshold and add a second maintenance surface for a security-sensitive piece of code (the whitelist guard). A concern is the correct Rails abstraction for shared controller behavior.

**Alternatives considered**:
- Inline in each controller — duplication, two places to update if the direction whitelist changes
- ApplicationController helper — too broad; sort support is Toxo-namespace specific
- Service object — over-abstraction; this is pure HTTP/controller-layer request handling with no business logic

## Decision 3: `Arel.sql` safety

**Decision**: Use `Arel.sql("#{col} IS NULL, #{col} #{dir}")` where `col` and `dir` are both controlled strings.

**Rationale**: Rails 5.2+ requires `Arel.sql()` for raw SQL fragments in `.order()` to prevent accidental string injection. Here `col` is the *value* from a whitelist hash (never the raw param key), and `dir` is validated against `%w[asc desc]`. The concatenation is safe. Using `Arel::Nodes::SqlLiteral` directly or constructing an `Arel::Nodes::Ordering` would add complexity without benefit.

**Alternatives considered**:
- Parameterized ORDER BY — not supported by SQL; ORDER BY cannot be parameterized
- Arel AST nodes — more verbose, no additional safety guarantee given the inputs are already controlled

## Decision 4: SORTABLE_COLUMNS as controller-level constant

**Decision**: Define `SORTABLE_COLUMNS` as a frozen constant on each controller class, not in the concern.

**Rationale**: Each controller sorts a different set of columns. The concern reads `self.class::SORTABLE_COLUMNS`, letting each subclass define its own whitelist while sharing the parsing/validation logic. This is idiomatic Ruby (template method via constant lookup) and avoids making the concern stateful or requiring configuration injection.

**Alternatives considered**:
- Concern-level default hash that controllers override — requires `included do` block and accessor, adds boilerplate
- Pass column map as argument to `apply_sort` — more explicit but pushes the concern's internals into the caller

## Confirmed: No index migration in this feature

Per user instruction. Index additions for `dispatch_date`, `AcceptanceDate`, `SampleStatus` on the `Samples` table are tracked separately. The sort will issue a filesort on those columns until indexes are added; this is acceptable at current data volumes.
