# Tasks: API Server-Side Sort Support

**Input**: Design documents from `specs/003-api-sort-support/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the `Toxo::Sortable` concern that both controllers will include. This is a blocking prerequisite for US1 and US2.

- [x] T001 Create concern file `app/controllers/concerns/toxo/sortable.rb` with `ALLOWED_DIRECTIONS` constant and `apply_sort` method using MariaDB 10.1-compatible null sort (`ORDER BY col IS NULL, col dir`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Write failing request specs that define expected sort behaviour. These specs must be RED before any implementation work begins (TDD per constitution Principle III).

**⚠️ CRITICAL**: No controller changes until specs are written and confirmed failing.

- [x] T002 [P] Add sort scenarios to `spec/requests/toxo/samples_spec.rb`: `GET /toxo/samples?sort=dispatch_date&direction=asc` returns samples in ascending dispatch_date order; `GET /toxo/samples?sort=code&direction=desc` returns descending; no-params request returns 200 without error.
- [x] T003 [P] Create `spec/requests/toxo/measurements_spec.rb` with sort scenarios: `GET /toxo/measurements?sort=authorized_at&direction=desc` returns descending; `GET /toxo/measurements?sort=sample_code&direction=asc` returns ascending; no-params returns 200; no `pp` output visible in logs.
- [x] T004 [P] Add invalid-params scenario to `spec/requests/toxo/samples_spec.rb`: `GET /toxo/samples?sort=sql_injection&direction=DROP` returns 200 with default order (sort silently ignored).

**Checkpoint**: Run `bundle exec rspec spec/requests/toxo/` — new examples must be RED, existing must be GREEN.

---

## Phase 3: User Story 1 — Sort Samples (Priority: P1) 🎯 MVP

**Goal**: `GET /toxo/samples` accepts `sort` and `direction` params and returns DB-sorted results.

**Independent Test**: `GET /toxo/samples?sort=dispatch_date&direction=asc` returns samples ordered by dispatch_date with nulls last.

### Implementation for User Story 1

- [x] T005 [US1] Add `include Toxo::Sortable` and define `SORTABLE_COLUMNS` constant in `app/controllers/toxo/samples_controller.rb` (columns: `code → Samples.Code`, `lot → Samples.Lot`, `dispatch_date → Samples.dispatch_date`, `acceptance_date → Samples.AcceptanceDate`, `status → Samples.SampleStatus`)
- [x] T006 [US1] Replace `policy_scope(Toxo::Sample.all)` with `apply_sort(policy_scope(Toxo::Sample.all))` in `Toxo::SamplesController#index` in `app/controllers/toxo/samples_controller.rb`

**Checkpoint**: `bundle exec rspec spec/requests/toxo/samples_spec.rb` — all examples GREEN.

---

## Phase 4: User Story 2 — Sort Measurements (Priority: P1)

**Goal**: `GET /toxo/measurements` accepts `sort` and `direction` params and returns DB-sorted results.

**Independent Test**: `GET /toxo/measurements?sort=authorized_at&direction=desc` returns measurements ordered by AuthorizedAt descending with nulls last.

### Implementation for User Story 2

- [x] T007 [US2] Add `include Toxo::Sortable` and define `SORTABLE_COLUMNS` constant in `app/controllers/toxo/measurements_controller.rb` (columns: `sample_code → Samples.Code`, `lot → Samples.Lot`, `authorized_at → Measurements.AuthorizedAt`, `project → Measurements.ProjectId`)
- [x] T008 [US2] Replace `policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)` with `apply_sort(...)` wrapper in `Toxo::MeasurementsController#index` in `app/controllers/toxo/measurements_controller.rb`

**Checkpoint**: `bundle exec rspec spec/requests/toxo/measurements_spec.rb` — all examples GREEN.

---

## Phase 5: User Story 3 — Reject Invalid Sort Params (Priority: P2)

**Goal**: Unknown sort columns or invalid directions are silently ignored; no SQL injection surface.

**Independent Test**: `GET /toxo/samples?sort=unknown_col&direction=DROP TABLE` returns 200 with default order.

*This story is covered structurally by the `Toxo::Sortable` concern implemented in Phase 1 (whitelist hash lookup returns nil for unknown columns; direction guard rejects non-`asc`/`desc` values). No additional implementation is required — only verify the spec scenarios added in T004 pass.*

- [x] T009 [P] [US3] Run `bundle exec rspec spec/requests/toxo/samples_spec.rb` and confirm invalid-params scenario (T004) is GREEN after Phase 3 implementation.

**Checkpoint**: Invalid-params spec GREEN with zero implementation changes needed beyond the concern.

---

## Phase 6: User Story 4 — Remove Debug Output (Priority: P1)

**Goal**: Remove `pp` debug call from `Toxo::MeasurementsController#index`.

**Independent Test**: No stdout/log output from `pp` when measurements endpoint is called.

- [x] T010 [US4] Delete line 7 (`pp @measurements.map { |m| serialize_measurement(m) }`) from `app/controllers/toxo/measurements_controller.rb`

**Checkpoint**: `bundle exec rspec spec/requests/toxo/measurements_spec.rb` still GREEN; no `pp` output visible when running specs.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T011 [P] Run full test suite `bundle exec rspec` and confirm zero regressions across all namespaces.
- [x] T012 [P] Verify `Toxo::Sortable` concern file follows Rails autoloading convention (nested module path matches directory structure under `app/controllers/concerns/toxo/`).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — create concern first.
- **Phase 2 (Specs)**: Depends on Phase 1 — specs reference the concern's interface.
- **Phase 3 (US1)**: Depends on Phase 1 and 2 — concern must exist; specs must be RED.
- **Phase 4 (US2)**: Depends on Phase 1 and 2 — can start in parallel with Phase 3 (different file).
- **Phase 5 (US3)**: Depends on Phase 3 — validated automatically by T009 after US1 implementation.
- **Phase 6 (US4)**: Independent — can run at any point after Phase 2 specs are written.
- **Phase 7 (Polish)**: Depends on all phases complete.

### User Story Dependencies

- **US1 (P1 — Sort Samples)**: Unblocked after Phase 1 and 2.
- **US2 (P1 — Sort Measurements)**: Unblocked after Phase 1 and 2. **Parallel with US1** (different controller file).
- **US3 (P2 — Invalid Params)**: Covered by the concern; verification only after US1.
- **US4 (P1 — Remove pp)**: Independent, no story dependencies.

### Parallel Opportunities

- T002, T003, T004 (spec writing) can run in parallel — different files.
- T005+T006 (US1) and T007+T008 (US2) can run in parallel — different controller files, both use same concern.
- T010 (US4 — remove pp) can run in parallel with US1 and US2 implementation.

---

## Parallel Example: US1 + US2 + US4

```
After Phase 1 concern is created and Phase 2 specs are RED:

  → Developer/agent A: T005, T006 (samples controller)
  → Developer/agent B: T007, T008 (measurements controller)
  → Developer/agent C: T010 (remove pp — 1 line deletion)
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Create `Toxo::Sortable` concern (T001)
2. Complete Phase 2: Write failing specs (T002, T003, T004)
3. Complete Phase 3: Wire up samples controller (T005, T006)
4. **STOP and VALIDATE**: `bundle exec rspec spec/requests/toxo/samples_spec.rb` — all GREEN
5. Continue with US2, US4, and Polish

### Full Delivery Order

1. T001 → T002+T003+T004 (parallel) → T005+T006+T007+T008+T010 (parallel) → T009 → T011+T012

---

## Notes

- [P] = different files, no dependencies on incomplete tasks
- Constitution Principle III: specs MUST be RED before implementation — do not skip Phase 2
- MariaDB 10.1 null sort: `ORDER BY col IS NULL, col dir` (see research.md Decision 1)
- `Arel.sql` receives only controlled strings — never raw params (see research.md Decision 3)
- No index migration in this feature (tracked separately)
