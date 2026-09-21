# Data Model: Rails 7.2 → 8.0 Upgrade

**Feature**: 009-rails-80-upgrade | **Date**: 2026-08-18

## Application data model: unchanged

**This upgrade introduces no schema change of any kind** — no tables, columns, indexes, constraints,
or migrations. `db/schema.rb` must be byte-identical before and after (FR-020).

That is not a passing remark. `LabSample` is shared by nine applications, and the user's standing
rules forbid altering a shared table without explicit confirmation. Rails 8.0 also changes schema
*dumping* to sort columns alphabetically, which makes a routine `db:schema:dump` look like a large
legitimate change while potentially being destructive — spec 007 lost two table definitions this
way. Any schema difference observed during this upgrade is a defect in the upgrade, not a product
of it.

The entities below are therefore not database models. They are the **state objects of the upgrade
itself** — the things that get recorded, compared, and gated on.

---

## Upgrade-state entities

### 1. Baseline

The measured pre-upgrade state. Every "unchanged" claim is asserted against this.

| Field | Value at planning time | Notes |
|---|---|---|
| Framework version | `7.2.3` | From `Gemfile.lock` |
| Runtime version | `3.4.10` | Ruby; unchanged by this upgrade |
| Spec file count | 98 | `find spec -name "*_spec.rb"` |
| Example count | *recorded at Phase 0* | Must not decrease (FR-022) |
| Failure count | *recorded at Phase 0* | Must be 0 to proceed |
| Lockfile snapshot | *copied at Phase 0* | The comparison basis for FR-004 |
| Schema version | *recorded at Phase 0* | Must not decrease (FR-020) |
| Route inventory | *captured at Phase 0* | The "before" side for the reachability check (FR-010, SC-006) |
| Encryption probe | *persisted at Phase 0* | An `ApiAccount#settings` value encrypted by the **old** runtime (FR-015, SC-010) |
| Commit reference | *recorded at Phase 0* | The revert target |

**Lifecycle**: recorded once at Phase 0 → compared at every subsequent gate → reproduced exactly on
revert (FR-025, SC-016).

**Rule**: if the baseline suite is not green, the upgrade does not start. Every later comparison is
meaningless otherwise.

**Rule (ordering)**: the route inventory and the encryption probe must be captured *before* any
dependency change. Both are "before" sides of later comparisons and cannot be reconstructed
afterwards — a probe encrypted by the new runtime proves only same-version behaviour, and a route
list captured post-upgrade cannot reveal what the upgrade added.

---

### 2. Blocking dependency

A gem whose declared bounds exclude Rails 8.0. Exactly two are known.

| Gem | Current | Declared bound | Resolution | Kind |
|---|---|---|---|---|
| `rails-i18n` | 7.0.10 | `railties (>= 6.0.0, < 8)` | Bump to 8.0.x | Runtime |
| `annotate` | 3.2.0 | `activerecord (>= 3.2, < 8.0)` | Replace with `annotaterb` 4.24.0 | Development/test |

**State transitions**: `declared blocker` → `resolution attempted` → `cleared` | `escalated`.

**Rule (FR-001)**: this set is *proven* by running resolution, not by trusting the scan. Scanning
declared bounds finds gems that say they are incompatible; it cannot find gems that merely are. Any
third blocker surfaced at resolution enters this table at equal priority.

---

### 3. Annotation state

Tracked separately because the fork swap and the annotation regeneration are **different
operations**, and conflating them is the main way this step goes wrong.

| Property | Verified value |
|---|---|
| Models total | 58 |
| Models carrying `# == Schema Information` | 39 |
| Models without annotations | 19 |
| Configuration file | **None** — no `.annotaterb.yml`, no `auto_annotate_models.rake` |
| Annotation position | Top of file (line 1) |

**Rule (FR-003)**: swapping the gem is required (it unblocks resolution); **regenerating annotations
is not**. A blind regeneration would annotate all 58 models, producing a 19-file diff unrelated to
this upgrade and burying the changes that matter. Generate to a scratch state, diff against current
blocks, then decide. Deferring regeneration entirely is an acceptable outcome.

---

### 4. Namespace

The unit at which contract equivalence is verified. Eleven, taken from `config/routes.rb` — which is
authoritative; the table in `CLAUDE.md` lists nine and omits `toxo` and `diagnostyka_precyzyjna`.

| Namespace | Route line | Consumer | Behavioural comparison |
|---|---|---|---|
| `webhook` | 7 | Machine-to-machine (Bearer) | Required |
| `v1` | 22 | Polish domestic labs | Required |
| `fv1` | 48 | Foreign institutions | Required — **partner-facing** |
| `nume` | 70 | NUME lab system | Required |
| `lalen` | 92 | Lalen/FFTB partner | Required — **partner-facing** |
| `toxo` | 123 | Toxo portal | Required |
| `masdiag` | 149 | Internal ops | Required |
| `masdiag_mailer` | 173 | Email notifications | Required |
| `patient_portal` | 209 | Patient-facing | **Structural only** — unused; excluded per spec 007 |
| `regspec` | 219 | REGSPEC system | Required |
| `diagnostyka_precyzyjna` | 229 | DP integration | Required |

**Per-namespace record** (feeds FR-009a): namespace → specs exercised → pass/fail → coverage
assessment → whether coverage substantiates the equivalence claim.

**Rule (FR-009)**: equivalence means the same specs pass with **unchanged assertions**. A modified
assertion is a contract change, not a test fix.

---

### 5. Framework default

A behaviour that activates only under `load_defaults 8.0`. Each is a separate recorded decision
(FR-019).

| Default | Relevance here | Decision |
|---|---|---|
| `active_job.enqueue_after_transaction_commit` (global setting deprecated) | **Highest** — framework half of spec 007's partner-notification guard; currently *inherited*, not set | Set **explicitly** (FR-014) |
| `Regexp.timeout` | 6 regex sites; one validates partner-supplied email | Verify all 6; test the partner one properly (FR-017) |
| Schema dump column ordering | Cosmetic, but the dump path is destructive from a stale DB | Do not regenerate (FR-020) |
| Asset pipeline default → Propshaft | `/jobs` dashboard is the only asset surface; zero asset config in `config/` | Verify dashboard *renders* (FR-008a) |
| Remaining 8.0 defaults | Reviewed individually via `new_framework_defaults_8_0.rb` | Recorded per item (FR-006, FR-019) |

**State transitions**: `inherited from 7.2` → `reviewed` → `adopted` | `adopted-with-override` |
`deferred with reason`.

---

### 6. Equivalence report

Per-namespace evidence for FR-009a. Names every namespace whose coverage is too thin for the suite
alone to substantiate the claim — so residual risk is visible at deployment rather than discovered
by a partner.

### 7. Upgrade record

The written account (FR-024): versions before/after, every dependency that moved and why, every
default adopted and why, every deferral with its reason, and the revert procedure.

**Rule (FR-025)**: revert restores the framework version **and** dependent code together. Spec 007
reverted only the lockfile, left newer code in place, and produced 13 failures that masked the real
state.

---

## Invariants

Continuously true; violation stops the upgrade.

| # | Invariant | Source |
|---|---|---|
| I1 | `db/schema.rb` unchanged; no table or column lost; schema version does not decrease | FR-020 |
| I2 | No gem moves in the lockfile except the framework, the two blockers, and gems the framework forces | FR-004 |
| I3 | No spec assertion is weakened, relaxed, or deleted | FR-009 |
| I4 | Example count never decreases from baseline | FR-022 |
| I5 | Ruby stays 3.4.10 | Technical Context |
| I6 | No application code in `app/` changes, except where a genuine incompatibility is found and recorded | Plan scope |
| I7 | A committed kit assignment yields exactly 1 partner notification; a rolled-back one yields 0 | FR-013 |
| I8 | No endpoint becomes reachable that was previously refused | FR-010 |
