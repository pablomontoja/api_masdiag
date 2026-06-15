# Feature Specification: API Server-Side Sort Support

**Feature Branch**: `003-api-sort-support`

**Created**: 2026-06-10

**Status**: Draft

**Input**: Add server-side sorting support to toxo API samples and measurements endpoints, following plans/002-toxo-api-sort-changes.md but without database index migration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sort Samples by Column (Priority: P1)

A toxo client requests the samples list with a sort column and direction. The API returns results ordered by the requested column, scoped to the authenticated contractor.

**Why this priority**: The primary deliverable — enables the toxo frontend to delegate sorting to the database instead of doing it in Ruby.

**Independent Test**: Send `GET /toxo/samples?sort=dispatch_date&direction=asc` and verify the returned list is ordered by dispatch_date ascending.

**Acceptance Scenarios**:

1. **Given** a contractor with multiple samples, **When** `GET /toxo/samples?sort=dispatch_date&direction=asc`, **Then** samples are returned ordered by dispatch_date ascending (nulls last).
2. **Given** a contractor with multiple samples, **When** `GET /toxo/samples?sort=code&direction=desc`, **Then** samples are returned ordered by Code descending.
3. **Given** a contractor with multiple samples, **When** `GET /toxo/samples` (no sort params), **Then** samples are returned in the default database order (no regression).

---

### User Story 2 - Sort Measurements by Column (Priority: P1)

A toxo client requests the measurements list with a sort column and direction. The API returns results ordered by the requested column, scoped to the authenticated contractor's patients.

**Why this priority**: Equal priority — measurements table benefits more from database-side sort due to the chainable ActiveRecord scope.

**Independent Test**: Send `GET /toxo/measurements?sort=authorized_at&direction=desc` and verify the returned list is ordered by AuthorizedAt descending.

**Acceptance Scenarios**:

1. **Given** a contractor with multiple measurements, **When** `GET /toxo/measurements?sort=authorized_at&direction=desc`, **Then** measurements are returned ordered by AuthorizedAt descending (nulls last).
2. **Given** a contractor with multiple measurements, **When** `GET /toxo/measurements?sort=sample_code&direction=asc`, **Then** measurements are returned ordered by sample Code ascending.
3. **Given** a contractor with multiple measurements, **When** `GET /toxo/measurements` (no sort params), **Then** measurements are returned in the default order (no regression).

---

### User Story 3 - Reject Invalid Sort Parameters (Priority: P2)

When an unknown sort column or invalid direction is supplied, the API ignores the sort parameters and returns the default unsorted list. No 422 or error response — silent fallback.

**Why this priority**: Security requirement — unknown params must never reach the database query. Graceful degradation is better than an error for backward compatibility.

**Independent Test**: Send `GET /toxo/samples?sort=unknown_col&direction=asc` and verify a 200 response with unsorted results (no SQL injection surface).

**Acceptance Scenarios**:

1. **Given** any request, **When** `sort` param is not in the allowed column whitelist, **Then** sort is silently ignored and default order is returned.
2. **Given** any request, **When** `direction` param is not `asc` or `desc`, **Then** sort is silently ignored and default order is returned.

---

### User Story 4 - Remove Debug Output from Measurements (Priority: P1)

The measurements controller has a leftover `pp` debug call on line 7. It must be removed as part of this change.

**Why this priority**: The debug call logs all measurement data to stdout in production — data privacy violation.

**Independent Test**: Run the test suite; verify no stdout contamination from the measurements endpoint.

**Acceptance Scenarios**:

1. **Given** a request to `GET /toxo/measurements`, **When** the response is returned, **Then** no debug output is written to stdout/logs.

---

### Edge Cases

- What happens when `sort` is present but `direction` is missing (or vice versa)? → Both must be valid for sort to apply; either alone is silently ignored.
- What happens when the sorted column contains nulls? → Nulls are sorted last (workaround for MariaDB 10.1 which does not support `NULLS LAST` syntax).
- Can a client inject SQL via sort parameters? → No — only whitelisted column strings (defined in the controller) are ever passed to the query.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `GET /toxo/samples` MUST accept optional `sort` and `direction` query parameters.
- **FR-002**: `GET /toxo/measurements` MUST accept optional `sort` and `direction` query parameters.
- **FR-003**: Sort column MUST be validated against a whitelist; raw param values MUST NOT reach the query.
- **FR-004**: Direction MUST be restricted to `asc` or `desc`; any other value MUST be treated as absent.
- **FR-005**: When either `sort` or `direction` is absent or invalid, the endpoint MUST return results in default order (no error).
- **FR-006**: Null values in the sort column MUST appear last regardless of sort direction.
- **FR-007**: The debug `pp` call in `Toxo::MeasurementsController#index` MUST be removed.
- **FR-008**: Sorting logic shared between the two controllers MUST be extracted to a shared concern (`Toxo::Sortable`) to avoid duplication.
- **FR-009**: All existing request specs MUST continue to pass without modification.

### Key Entities

- **Toxo::Sample**: Laboratory sample record; sortable fields: Code, Lot, dispatch_date, AcceptanceDate, SampleStatus.
- **Measurement**: Test measurement linked to a sample; sortable fields: Samples.Code, Samples.Lot, AuthorizedAt, ProjectId.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sorting by any whitelisted column produces results in the correct order as verified by request specs.
- **SC-002**: Passing an unknown sort column or direction produces the same response as passing no sort params (no errors, no SQL injection).
- **SC-003**: All existing toxo request specs pass without modification after the change.
- **SC-004**: No debug output appears in application logs when the measurements endpoint is called.
- **SC-005**: The sort whitelisting logic exists in exactly one place (the `Toxo::Sortable` concern), not duplicated across controllers.

## Assumptions

- MariaDB 10.1 is the database engine; `NULLS LAST` SQL syntax is not supported. The `IS NULL` sort trick (`ORDER BY col IS NULL, col dir`) is used instead.
- No database index migration is included in this feature (tracked separately).
- The toxo Bearer token auth flow (session-based, not HTTP Basic) is already working and requires no changes.
- The `Toxo::Sortable` concern is placed in `app/controllers/concerns/` (no new directory needed).
- The change is backwards-compatible: clients not passing sort params experience no behavior change.
