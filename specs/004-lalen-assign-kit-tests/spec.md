# Feature Specification: Lalen Kit Tests Assignment

**Feature Branch**: `004-lalen-assign-kit-tests`

**Created**: 2026-06-24

**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Assign Tests to an Active Kit (Priority: P1)

A Lalen partner consumer (authenticated via the Lalen namespace) submits a list of test identifiers for a kit that is currently in an assignable state (IN_STOCK or ACTIVE). The system records the test assignments, replacing any previously assigned tests, and notifies the external Lalen lab system in the background.

**Why this priority**: This is the core happy path — the most common operation for Lalen partners activating kits with a test panel.

**Independent Test**: Can be fully tested by submitting a valid barcode + test list for an IN_STOCK kit and verifying the 201 response includes the assigned tests.

**Acceptance Scenarios**:

1. **Given** a valid authenticated Lalen partner account and an IN_STOCK kit belonging to that account, **When** the partner submits the kit barcode and a non-empty list of valid test keys, **Then** the system responds 201 with the barcode, current kit status, and the newly assigned test keys.
2. **Given** a kit that previously had tests assigned, **When** the partner submits a new list of test keys, **Then** the old assignments are replaced entirely by the new list.
3. **Given** an ACTIVE kit, **When** the partner submits a valid barcode and test list, **Then** the response is 201 and the external lab system is notified asynchronously.

---

### User Story 2 - Assign Tests to an Unregistered Kit with No Prior Assignments (Priority: P2)

A partner submits test assignments for a kit whose status is UNREGISTERED and that has no currently assigned tests. The system allows this as a special case to support kits that have not yet been formally registered.

**Why this priority**: Supports an edge-case workflow where test assignment precedes kit registration; blocking this would prevent valid partner operations.

**Independent Test**: Can be tested by submitting an UNREGISTERED kit barcode (with no existing assignments) and verifying the 201 response.

**Acceptance Scenarios**:

1. **Given** an UNREGISTERED kit with no currently assigned tests, **When** a partner submits a valid barcode and test list, **Then** the system responds 201 with the assigned tests.
2. **Given** an UNREGISTERED kit that already has tests assigned, **When** a partner attempts to assign tests, **Then** the system responds 422 with a descriptive validation error.

---

### User Story 3 - Rejection of Invalid Requests (Priority: P3)

The system rejects requests that reference unknown barcodes, invalid test keys, or kits in non-assignable states, returning actionable error responses.

**Why this priority**: Protects data integrity and provides clear feedback to Lalen partner integrations.

**Independent Test**: Can be tested independently by sending requests with bad barcodes or invalid test keys and checking error responses.

**Acceptance Scenarios**:

1. **Given** a barcode that does not exist for the authenticated account, **When** the partner submits a test assignment request, **Then** the system responds 422 with the message "A such sample code was not found for your institution".
2. **Given** a kit in a non-assignable status (e.g., COMPLETED, CANCELLED), **When** the partner attempts to assign tests, **Then** the system responds 422 with a message describing the invalid status.
3. **Given** one or more test keys that are not recognised by the system, **When** the partner submits the assignment, **Then** the system responds 422 listing the unrecognised test keys.
4. **Given** an empty or missing tests list in the request, **When** the partner submits the request, **Then** the system responds 422 indicating that at least one test must be specified.

---

### User Story 4 - Background Job Notifies External Lab System (Priority: P1)

After a successful test assignment, the system dispatches a background job that sends the kit barcode and assigned test keys to the external Lalen lab system. This mirrors the pattern of the existing kit registration notification job.

**Why this priority**: Without this notification the external lab system remains unaware of the assignment — the integration would be incomplete and test processing at the lab would not begin.

**Independent Test**: Can be tested by triggering the job directly with a sample barcode and a list of test keys and verifying the external system receives the correct payload.

**Acceptance Scenarios**:

1. **Given** a kit with tests successfully assigned, **When** the background job runs, **Then** it sends the kit barcode and the list of assigned test keys to the external Lalen lab system and completes without error.
2. **Given** the external lab system returns a non-success response, **When** the job encounters the error, **Then** the job raises an exception so the retry mechanism re-attempts delivery with exponential backoff.
3. **Given** the job has exhausted all retry attempts, **When** the final attempt also fails, **Then** the error is captured and reported to the error tracking system.
4. **Given** the job data is invalid (e.g., missing barcode or empty test list), **When** the job runs, **Then** it raises a descriptive error rather than sending a malformed payload to the external system.

---

### Edge Cases

- What happens when the barcode is submitted in mixed case? — The system normalises barcodes to uppercase before lookup.
- What happens when the external lab system is temporarily unavailable? — The background notification job retries with exponential backoff; the 201 response is still returned to the partner immediately.
- What happens when the same test key appears multiple times in the request? — Duplicates are deduplicated silently; only unique test assignments are stored.
- What happens when the partner submits an empty array for tests? — Treated as a validation error (422).
- What happens if the job is enqueued but the kit's test assignments are modified before the job runs? — The job reads the assigned tests at enqueue time (passed as arguments), not at execution time, to avoid stale-data races.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow authenticated Lalen partner accounts to assign one or more tests to a kit identified by its barcode.
- **FR-002**: The system MUST replace all existing test assignments on the kit when a new assignment request is submitted (full replacement, not additive).
- **FR-003**: The system MUST only permit test assignment when the kit status is IN_STOCK, ACTIVE, or UNREGISTERED (UNREGISTERED only when the kit has no prior test assignments).
- **FR-004**: The system MUST reject assignment requests for kits in any other status with a 422 response and a descriptive error message.
- **FR-005**: The system MUST validate that all submitted test keys are recognised; requests containing any unrecognised keys MUST be rejected with a 422 response listing the invalid keys.
- **FR-006**: The system MUST reject requests with an empty or absent tests list with a 422 response.
- **FR-007**: The system MUST normalise the barcode to uppercase before performing the kit lookup.
- **FR-008**: The system MUST return 422 when no kit matching the barcode exists for the authenticated account, consistent with existing Lalen namespace error handling.
- **FR-009**: On successful assignment, the system MUST enqueue a background notification job to the external Lalen lab system, following the same retry-with-backoff pattern used by the existing kit registration job.
- **FR-010**: The successful response MUST include the barcode, the current kit status, and the list of assigned test keys.
- **FR-011**: The background notification MUST be fault-tolerant: a failure to notify the external system MUST NOT cause the assignment to be rolled back or the 201 response to be withheld.
- **FR-012**: The background job MUST receive the kit barcode and the list of assigned test keys as arguments at enqueue time.
- **FR-013**: The background job MUST validate its arguments before sending; if the barcode is absent or the test list is empty, it MUST raise a descriptive error without contacting the external system.
- **FR-014**: The background job MUST capture and report errors to the error tracking system on every failed attempt, including final failure after all retries are exhausted.
- **FR-015**: The background job MUST use the same authenticated connection to the external Lalen system as the existing kit registration job.

### Key Entities

- **Kit**: A diagnostic test kit identified by a unique barcode, owned by an account, and carrying a lifecycle status. The target entity being updated.
- **Test**: A named diagnostic test identified by a unique API key (`api_key` slug). Multiple tests can be assigned to one kit.
- **Kit Test Assignment**: The association between a kit and one or more tests. Replaced atomically on each assignment request.
- **External Lab Notification**: An asynchronous message sent to the Lalen lab system confirming the test assignments; delivered via background job.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of valid assignment requests (correct barcode, valid test keys, assignable kit status) receive a 201 response with the correct payload.
- **SC-002**: 100% of requests with invalid barcodes, unrecognised test keys, or non-assignable kit statuses receive the appropriate 4xx error response with a descriptive message.
- **SC-003**: The external lab system receives notification for every successful assignment; notifications that fail initially are retried and delivered within a reasonable time under normal conditions.
- **SC-004**: Partners can assign tests to a kit and receive confirmation without waiting for the external lab notification to complete.
- **SC-005**: Every failed notification attempt is captured in the error tracking system, providing full observability over integration failures with zero manual intervention required to detect them.

## Assumptions

- The Lalen namespace already enforces partner-level authentication and account scoping; this feature inherits those controls without modification.
- "Tests" are pre-existing entities in the system, each with a stable `api_key` slug; this feature does not create or manage test definitions.
- The external Lalen lab system exposes an endpoint that accepts kit test assignment payloads; the payload structure mirrors the pattern already established by the kit registration endpoint.
- Barcodes are treated as case-insensitive identifiers; uppercase normalisation is the canonical form.
- The kit status vocabulary (IN_STOCK, ACTIVE, UNREGISTERED, etc.) is already defined in the system; this feature does not alter status transitions.
- Duplicate test keys in a single request are silently deduplicated (no error raised).
- The `account_id` scoping ensures a partner can only assign tests to kits belonging to their own account.
- The background job passes the assigned test list as job arguments (not re-queried from the database at execution time) to avoid stale-data races between enqueue and execution.
- The external Lalen lab API endpoint for test assignment already exists and accepts the kit barcode plus a list of test keys; this feature does not require changes to the external system.
