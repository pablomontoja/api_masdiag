# Rails 7.2 Upgrade — Handover Record

**Feature**: 007-rails-72-upgrade | **Completed**: 2026-08-17 | **Branch**: `007-rails-72-upgrade`
**Task**: T051 | **Satisfies**: FR-034, SC-018

Written so another developer can act on this without reading the diff.

---

## What changed

`api_masdiag` moved from **Rails 7.1.6 to 7.2.3**, on Ruby 3.3.7 (unchanged), with
`config.load_defaults` also raised to **7.2**.

Six commits, each independently revertible:

| Commit | What | Ships alone? |
|--------|------|--------------|
| `97b6f8d` | Declare `csv` + `base64` as explicit dependencies | ✅ yes |
| `b6b5826` | Notify Lalen partner only after the assignment commits | ✅ yes |
| `aff1ed2` | Add `regspec` smoke checks | ✅ yes |
| `dc77b4b` | Upgrade Rails 7.1.6 → 7.2.3 (+ Lockbox 2.2.0, deprecation cleanup) | depends on the above |
| `468db87` | Verification records + stale retry-docs fix | ✅ yes |
| `51028d4` | Adopt `load_defaults 7.2` | revertible alone |

The first three landed **on Rails 7.1** and fix real problems regardless of whether
the upgrade proceeds. The last is separable: reverting it leaves a supported
Rails 7.2 + 7.1-defaults configuration without touching the framework version.

### Two defects fixed along the way

**1. Undeclared standard library gems.** Six files `require "csv"` and one requires
`"base64"`, but neither appeared in the `Gemfile`. Both stopped being Ruby default
gems in 3.4. These are recurring-report and mailer paths, so the failure mode would
have been *a report silently not arriving*, not an obvious error.

**2. Partner notified about uncommitted writes.** `Fv1::KitController#assign_tests`
enqueued `LalenApi::AssignKitTestsJob` — which POSTs a kit barcode to an external
partner and retries 10× — from *inside* the transaction recording the assignment. A
rollback left the partner repeatedly told about an assignment that was never
persisted, with no way to withdraw it. The notification now sits after the
transaction block.

### Dependency changes

Only what was necessary:

- 13 Rails components `7.1.6` → `7.2.3`
- `lockbox` `1.2.0` → **`2.2.0`** (forced — see below)
- `csv` `3.3.6` added, `base64` `0.3.0` made explicit
- `useragent` added / `mutex_m` removed (transitive)

`rspec-rails` (7.1.1), `solid_queue` (1.4.0), `sentry` (6.6.2) and ~146 others were
deliberately **held**.

### Code cleanup

- `serialize :json, ::ActiveRecord::Coders::JSON` → `coder:` keyword
- `ActiveRecord::Base.connection` → `with_connection` (3 sites)
- legacy hash-syntax `enum` → keyword form (2 sites; a Rails 8.0 removal, fixed early)

---

## What was verified

| Check | Result |
|-------|--------|
| Test suite | **755 examples, 0 failures** (baseline 737; none lost) |
| Deprecation warnings | **0** |
| API namespaces | **8 of 8** pass (`patient_portal` excluded as dormant) |
| LabSample schema | **unchanged** — only the `[7.1]`→`[7.2]` dump annotation |
| Field-level encryption | Lockbox 2.2 round-trips correctly on AR 7.2.3 |
| Job timing | Verified against the **real Solid Queue adapter**, both paths |
| Suite runtime | 42.0s vs 38.87s baseline (ceiling was 58.3s) |
| Ruby version pins | All four still agree at 3.3.7 |

Supporting detail: `baseline.md`, `audit-verification.md`, `equivalence-report.md`,
`compatibility-report.md`, `deprecations.md`.

---

## Three findings worth knowing

### 1. The `lockbox` pin inverted rather than lifted

The `Gemfile` said *"Lockbox >= 2.2 refuses to load on Active Record 7.1"*. The gem's
actual guard is `if ar_version < 7.2 → raise`, meaning **2.2.0 requires AR ≥ 7.2**.
The two versions have disjoint supported ranges, so Rails and Lockbox had to move in
one commit. The misleading comment has been corrected.

### 2. Transaction-aware enqueuing needed BOTH the code fix and the defaults change

Rails 7.2's `enqueue_after_transaction_commit` is gated behind `load_defaults 7.2`.
Immediately after the version bump — defaults still at 7.1 — it read `:never`, and the
real Solid Queue adapter confirmed a job enqueued inside a rolled-back transaction
still persisted:

```
# with load_defaults 7.1
fixed arrangement, rollback -> 0 job(s)
old arrangement,   rollback -> 1 job(s)   ← the bug, reproducible on 7.2.3
```

After adopting `load_defaults 7.2` (`51028d4`), Solid Queue's adapter opts in and the
framework defers enqueueing app-wide:

```
# with load_defaults 7.2
mid-txn rows:   0
after rollback: 0
after commit:   1
```

**Both layers matter and neither is redundant.** The code fix held the Lalen case
during the window between the bump and the defaults change, and still holds if the
defaults commit is ever reverted. The default protects every *other* enqueue site,
including ones added later by developers unaware of the constraint.

### 3. A bare `bundle update` would have wrecked the upgrade

It resolves cleanly — that is the trap — while sweeping in ~40 unrelated bumps
including `rspec-rails` 7→8 and `sentry` 5→6. Always use:

```bash
bundle lock --conservative --update rails lockbox
```

---

## What was deferred

| Item | Why | Revisit when |
|------|-----|--------------|
| **Ruby 3.4** | One variable at a time; 3.3 supported well past this work | Separate spec. `csv`/`base64` already handled; `observer` (via `factory_bot`) still outstanding |
| **`patient_portal` verification** | Dormant, 2 read-only endpoints, implementation expected to change | If it returns to active use |
| **Extracting `kit_controller#assign_tests` to a service object** | Exceeds the 15-line controller threshold (Constitution II/VI), but refactoring a partner-facing endpoint inside an upgrade would destroy attribution | Own spec, after 7.2 is stable |
| **`AssignKitTestsJob` retry policy** | Uses `polynomially_longer, attempts: 10`; the constitution mandates `exponentially_longer, attempts: 5`. Pre-existing, unrelated to the upgrade | Own ticket |
| **CI** | None exists; all verification was local and single-machine | Worth raising independently — the largest process risk here |

---

## ⚠️ Before release

**staging and production boot was not verified.** Both resolve their database host
from `credentials.dig(:db, :host)` (`10.82.66.250`), which refuses connections from
the development workstation — confirmed with a raw TCP probe, and equally true on
Rails 7.1. The framework and initializers load; only the DB connection fails.

**Action required**: boot both environments from a host with database access and
confirm before deploying. This is the one gate in the plan that could not be closed
locally.

---

## How to revert — tested, not assumed

Any single commit reverts independently. To return to Rails 7.1.6 entirely:

```bash
git checkout main -- Gemfile Gemfile.lock app/ db/ spec/
bundle install
bundle exec rspec
```

The pre-upgrade lockfile is preserved at
`specs/007-rails-72-upgrade/baseline-Gemfile.lock` (sha256 prefix `0fd2e0c9174e2751`).

To keep the two defect fixes while dropping the framework move, revert only `dc77b4b`.

### Revert was actually exercised (T062, SC-015)

Two attempts, and the first one is instructive:

**Dependencies only** (`Gemfile`/`Gemfile.lock` reverted, 7.2-era code left in place)
→ **13 failures**. Cause: `ActiveRecord::Base.with_connection` is a Rails 7.2 API and
raises `NoMethodError` on 7.1. Not a defect — a demonstration that **the dependency
revert and the code revert must be done together.** Reverting only the lockfile leaves
a broken tree.

**Full revert** (dependencies *and* `app/`, `db/`, `spec/`) → **755 examples, 1 failure**,
and that failure is the US3 regression guard reporting *"2 transactions were open"* —
i.e. correctly detecting that `main`'s controller still enqueues inside the transaction.
The revert restored pre-fix behaviour exactly as intended, and the guard proved it.

Branch state was then restored and re-verified: **755 examples, 0 failures, 38.52s**
on Rails 7.2.3 / Lockbox 2.2.0.
