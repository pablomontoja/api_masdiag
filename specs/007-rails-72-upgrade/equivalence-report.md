# API Equivalence & Verification Report

**Feature**: 007-rails-72-upgrade | **Verified**: 2026-08-17
**Tasks**: T033–T037 | **Satisfies**: FR-018, FR-019, FR-020, FR-021, FR-023, SC-007, SC-008, SC-010, SC-011

## Framework state

| Property | Before | After |
|----------|--------|-------|
| Rails | 7.1.6 | **7.2.3** |
| Lockbox | 1.2.0 | **2.2.0** |
| Ruby | 3.3.7 | 3.3.7 *(unchanged)* |
| `load_defaults` | 7.1 | 7.1 *(unchanged — US5 deferred)* |

## T033 — Environment boot

| Environment | Result |
|-------------|--------|
| development | ✅ boots — Rails 7.2.3 / Ruby 3.3.7 |
| test | ✅ boots — Rails 7.2.3 / Ruby 3.3.7 |
| staging | ⚠️ **not verifiable on this host** |
| production | ⚠️ **not verifiable on this host** |

**Staging/production caveat**: both configurations resolve their database host from
`Rails.application.credentials.dig(:db, :host)`, which points at `10.82.66.250`.
That host refuses connections from this workstation (verified independently with a
raw TCP probe — `Connection refused`), so boot fails at
`ActiveRecord::ConnectionNotEstablished` *before* any application code runs.

This is a **network reachability limit of the development machine, not a Rails 7.2
defect**: the framework, all initializers, and the gem set load successfully; only
the DB connection fails. The same failure would occur on Rails 7.1 from this host.

**FR-018 is therefore partially verified.** Boot under staging/production settings
must be confirmed from a host with database access before release. Recorded as an
outstanding verification item rather than a passed gate.

## T034 — Schema integrity (FR-023, SC-010)

`bin/rails db:migrate RAILS_ENV=test` produced **one** change to `db/schema.rb`:

```diff
-ActiveRecord::Schema[7.1].define(version: 2026_08_14_102700) do
+ActiveRecord::Schema[7.2].define(version: 2026_08_14_102700) do
```

This is the schema-dump **format annotation**, which Rails restamps to the current
framework version. The migration version is **identical** (`2026_08_14_102700`) and
no table, column, index, or constraint differs.

**Verdict**: ✅ **Zero LabSample schema change.** No other application sharing the
database is affected.

## T035 — Test suite (FR-019, SC-007, SC-017)

| Metric | Baseline (7.1.6) | After (7.2.3) |
|--------|------------------|---------------|
| Examples | 737 | **755** |
| Failures | 0 | **0** |
| Runtime | 38.87s | **42.0s** |

Example growth: 737 → 741 (rollback specs, US3) → 755 (regspec smoke checks, US4).
**No example was lost or skipped.**

Runtime is within the SC-017 ceiling of 58.3s (+50% of the 38.87s baseline).

## T036 — Field-level encryption across the Lockbox major bump (FR-021)

Lockbox 2.2.0 requires Active Record ≥ 7.2 and raises below it, so this bump was
forced by the framework move rather than optional.

Verified by round-tripping a real encrypted attribute (`ApiAccount#settings`) under
the new stack:

```
Lockbox 2.2.0 / AR 7.2.3
decrypted: {:probe=>"sensitive-value"}
ciphertext opaque: true
```

**Verdict**: ✅ Encryption and decryption behave identically. Ciphertext does not
leak plaintext. Patient-data protection intact.

## T037 — Namespace equivalence (FR-020, SC-008)

All eight in-scope namespaces pass on Rails 7.2.3:

| Namespace | Examples | Failures |
|-----------|----------|----------|
| `v1/` | 12 | 0 |
| `fv1/` | 85 | 0 |
| `nume/` | 55 | 0 |
| `lalen/` | 8 | 0 |
| `masdiag/` | 13 | 0 |
| `masdiag_mailer/` | 28 | 0 |
| `regspec/` | **14** | 0 |
| `webhook/` | 12 | 0 |

`regspec` moved from **zero** coverage to 14 examples (SC-009), written and passing
on Rails 7.1 before the bump so they constitute a genuine before/after comparison.

`patient_portal/` is excluded by clarification — dormant, two read-only endpoints,
implementation expected to change.

**Verdict**: ✅ No response-contract change detected in any in-scope namespace.

## Dependency containment (FR-028)

The conservative targeted update (`bundle lock --conservative --update rails lockbox`)
moved **only**:

- 13 Rails components: `7.1.6` → `7.2.3`
- `lockbox`: `1.2.0` → `2.2.0`
- `useragent (0.16.11)` added (new transitive dependency)
- `mutex_m (0.3.0)` removed (no longer required)

Explicitly held at their previous versions, confirming the ~40-gem sweep was avoided:

| Gem | Version |
|-----|---------|
| `rspec-rails` | 7.1.1 |
| `solid_queue` | 1.4.0 |
| `sentry-ruby` / `sentry-rails` | 6.6.2 |
| `alba` | 3.10.0 |
| `oj` | 3.17.4 |
| `puma` | 8.0.2 |
| `mysql2` | 0.5.7 |

## T042–T045 — Job timing against the real Solid Queue adapter (FR-032, FR-033, SC-016)

Verified in the **development** environment, which uses the real
`ActiveJob::QueueAdapters::SolidQueueAdapter` rather than the in-memory `:test`
adapter the suite runs under. (Development's database is local and reachable; only
staging/production point at the remote host.)

### Key finding: the 7.2 transaction-aware default is NOT active

```
enqueue_after_transaction_commit: :never
```

Rails 7.2's transaction-aware enqueuing is gated behind `config.load_defaults 7.2`.
This upgrade deliberately keeps defaults at **7.1** (FR-017), so the framework
still enqueues immediately, inside the open transaction:

```
--- COMMIT path ---
  inside txn, open_transactions=1
  enqueued rows visible mid-txn: 1        ← written before commit
  after commit: 1 job(s) enqueued
--- ROLLBACK path ---
  after rollback: 1 job(s) enqueued       ← job SURVIVES the rollback
```

**A job enqueued inside a transaction still persists when that transaction rolls
back.** The framework provides no protection at the current defaults level.

### Consequence: the US3 code fix is what actually protects the partner

Comparing the two arrangements under the real adapter:

| Arrangement | Jobs enqueued after rollback |
|-------------|------------------------------|
| **Fixed** (notification after the transaction block) | **0** ✅ |
| Original (notification inside the block) | **1** ❌ — the defect |

This retroactively validates two planning decisions:

1. **Fixing the call site in code rather than relying on the framework default**
   (research R6). Had the fix been left to `enqueue_after_transaction_commit`, the
   defect would still be live today, because that setting is inactive until
   `load_defaults` reaches 7.2 — which this feature defers to US5 (P4, optional).
2. **Verifying against a real worker rather than the test adapter** (FR-033). The
   suite's in-memory adapter cannot distinguish these arrangements; only the real
   adapter shows the job row surviving a rollback.

**Verdict**: ✅ Both paths observed directly. Commit → exactly one notification.
Rollback → none.

## Outstanding

| Item | Why | Status |
|------|-----|--------|
| staging/production boot | DB host unreachable from this workstation | Must be confirmed from a host with database access before release |
| `load_defaults` → 7.2 | US5 (P4), deliberately deferred | Optional; note that this is what would activate transaction-aware enqueuing framework-wide |
