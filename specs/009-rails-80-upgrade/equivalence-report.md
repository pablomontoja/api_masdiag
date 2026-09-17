# Namespace Equivalence Report

**Feature**: 009-rails-80-upgrade | **Tasks**: T027–T030 | **Date**: 2026-08-18

Evidence for FR-009/FR-009a: every namespace's request specs pass after the framework change with
**unchanged assertions**.

| | Before | After |
|---|---|---|
| Rails | 7.2.3 | **8.0.5.1** |
| Ruby | 3.4.10 | 3.4.10 (unchanged) |
| Suite | 758 examples, 0 failures | **758 examples, 0 failures** |

## Pass 1 — after the framework bump, defaults still at 7.2

| Namespace | Examples | Result | Coverage | Claim strength |
|---|---:|---|---|---|
| `toxo` | 130 | ✅ 0 failures | 9 files | **Strong** |
| `fv1` | 85 | ✅ 0 failures | 8 files | **Strong** — partner-facing |
| `v1` | 84 | ✅ 0 failures | 8 files | **Strong** |
| `nume` | 55 | ✅ 0 failures | 7 files | **Strong** |
| `masdiag_mailer` | 28 | ✅ 0 failures | 1 file | Adequate — better than file count suggested |
| `regspec` | 14 | ✅ 0 failures | 4 files | Adequate |
| `masdiag` | 13 | ✅ 0 failures | 4 files | Adequate |
| `webhook` | 12 | ✅ 0 failures | 1 file | **Thin** |
| `lalen` | 8 | ✅ 0 failures | 2 files | **Thin** — partner-facing |
| `diagnostyka_precyzyjna` | 7 | ✅ 0 failures | 1 file | **Thin** |
| `patient_portal` | 0 | — structural only | 0 files | **None** |
| **Total** | **436** | **0 failures** | | |

## Pass 2 — after adopting `load_defaults 8.0`

| Namespace | Pass 1 | Pass 2 | Result |
|---|---:|---:|---|
| `toxo` | 130 | 130 | ✅ identical |
| `fv1` | 85 | 85 | ✅ identical |
| `v1` | 84 | 84 | ✅ identical |
| `nume` | 55 | 55 | ✅ identical |
| `masdiag_mailer` | 28 | 28 | ✅ identical |
| `regspec` | 14 | 14 | ✅ identical |
| `masdiag` | 13 | 13 | ✅ identical |
| `webhook` | 12 | 12 | ✅ identical |
| `lalen` | 8 | 8 | ✅ identical |
| `diagnostyka_precyzyjna` | 7 | 7 | ✅ identical |
| **Total** | **436** | **436** | **0 failures both passes** |

Full suite after adoption: **758 examples, 0 failures** — the same figure recorded on Rails 7.2.3
before any change, and again after the bump with defaults still at 7.2.

Verifying twice is what makes a defaults-induced failure distinguishable from a bump-induced one
(SC-013a). Neither pass produced one.

`git diff spec/` remained empty across both passes.

## The load-bearing verification: assertions were not touched

```
$ git diff spec/ | wc -l
0
$ git diff app/ | wc -l
0
```

**Zero lines changed** under `spec/` or `app/`. No assertion was weakened, relaxed or deleted to make
anything pass (FR-009, invariant I3), and no application code was modified (invariant I6). The specs
that pass on Rails 8.0.5.1 are byte-identical to the ones that passed on 7.2.3.

This is the claim that matters. A green suite after edited assertions would prove nothing.

## Cross-cutting checks

| Check | Task | Result |
|---|---|---|
| Route inventory | T029a | **Byte-identical** — `diff` of `bin/rails routes` before/after shows no change. No endpoint became newly reachable (SC-006, invariant I8) |
| Auth / validation / parameter examples | T029a–c | **111 examples, 0 failures** across all namespaces (`unauthorized`, `authoriz`, `invalid`, `missing`, `wrong`) |
| `params.require` sites | T029c | 25, all unmodified. The newer `params.expect` style remains out of scope (FR-012) |
| `db/schema.rb` | T026 | **Identical** to the baseline snapshot (FR-020, invariant I1) |
| `patient_portal` | T029 | Routes load, namespace mounted, not reachable unauthenticated. Behavioural comparison excluded per spec 007 |

## Honest limitations

The suite *is* the equivalence evidence (clarification, 2026-08-18), so the claim is only as strong
as coverage — and coverage is not uniform. Four namespaces are thin and one has none:

- **`lalen` (8 examples, 2 files)** — the most concerning. Partner-facing, and the namespace whose
  partner-notification ordering spec 007 had to fix. Its behaviour is further exercised by the
  commit/rollback verification in T033/T047, which does not depend on spec coverage.
- **`webhook` (12 examples, 1 file)** — machine-to-machine, Bearer auth.
- **`diagnostyka_precyzyjna` (7 examples, 1 file)** — thin.
- **`patient_portal` (0)** — no behavioural claim is made at all; structural verification only.

For these, "the suite passes" is a correspondingly weaker statement. It is recorded here rather than
folded into a green summary so the residual risk is visible at deployment time instead of being
discovered by a partner.

`masdiag_mailer` is the one namespace whose file count understated it: 1 file, but 28 examples.
File count is a poor proxy for coverage, which is why example counts are recorded above.
