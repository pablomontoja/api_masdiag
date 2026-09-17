# Baseline: Rails 7.2 → 8.0 Upgrade

**Feature**: 009-rails-80-upgrade | **Captured**: 2026-08-18

The measured pre-upgrade state. Every "unchanged" claim in this feature is asserted against what is
recorded here, and the revert procedure (FR-025) must reproduce it exactly.

---

## Runtime and framework (T001)

| Property | Value |
|---|---|
| Ruby | `3.4.10 (2026-06-30 revision 2b0b7728dc) +PRISM [x86_64-linux]` |
| Rails | `7.2.3` |
| `Gemfile` ruby directive | `3.4.10` |
| Branch | `009-rails-80-upgrade` |
| Commit SHA (revert target) | `61a22f89a67bacd4fd7f5555a0b73431350d023f` |

Ruby must remain 3.4.10 throughout (invariant I5). Rails 8.0.5.1 requires `>= 3.2.0`, already
satisfied — spec 008 paid that cost in advance.

## Test suite (T002)

| Metric | Value |
|---|---|
| **Examples** | **758** |
| **Failures** | **0** |
| Runtime | 37.85 s (3.6 s to load) |
| Spec files | 98 |

**Gate: PASSED.** The example count must never decrease from 758 (FR-022, SC-004).

> Note: 758 examples across 98 spec files. Spec 008 recorded 755; the increase reflects specs added
> since, which is expected and permitted — only a *decrease* is a finding.

## Snapshots (T003, T004, T005a)

| Artifact | Path | Size |
|---|---|---|
| Lockfile | `/tmp/baseline-009-Gemfile.lock` | 538 lines |
| Schema | `/tmp/baseline-009-schema.rb` | 1442 lines |
| Routes | `/tmp/baseline-009-routes.txt` | 146 lines |

**Schema version**: `2026_08_14_102700` — must not decrease (FR-020, SC-014).

These are the "before" sides of later comparisons. The route inventory in particular is the only
check that can detect an endpoint becoming newly reachable when no spec covers it (FR-010, SC-006,
invariant I8).

## Encryption probe (T005b)

Persisted **on Rails 7.2.3, before any dependency change**. A value written after the upgrade would
prove only same-version behaviour; cross-version compatibility requires ciphertext produced by the
old runtime.

| Property | Value |
|---|---|
| Model | `ApiAccount` |
| Username | `enc_probe_009` |
| **Record id** | **15** |
| Contractor id | 1 |
| Plaintext written | `{ probe: "pre-rails-80" }` |
| Decrypts on 7.2.3 | ✅ `{probe: "pre-rails-80"}` |
| Ciphertext opaque | ✅ contains no plaintext |
| Ciphertext size | 72 bytes |

**T031 reads this exact record after the upgrade.** If it is missing at that point, FR-015 is
unverifiable without redoing the upgrade — record it as a gap rather than substituting a fresh
record.

## Blocker set proof (T006, T007)

**Method**: temporarily set `gem "rails", "~> 8.0.5"`, run `bundle lock`, inspect the result, then
restore `Gemfile` and `Gemfile.lock` from the snapshots.

### Result: resolution SUCCEEDED — and that is the finding

The planning phase predicted a resolution *failure* naming both blockers. It did not fail. Bundler
resolved to Rails **8.0.5.1** and reached that state by **silently downgrading `annotate` from 3.2.0
to 2.6.5**.

| Gem | Before | After the probe | Assessment |
|---|---|---|---|
| `rails` | 7.2.3 | **8.0.5.1** | Target confirmed available |
| `rails-i18n` | 7.0.10 | **8.1.0** | Auto-resolved — see caveat below |
| `annotate` | 3.2.0 | **2.6.5** | ⚠️ **Silent downgrade to a 2014 release** |

126 lockfile lines changed; all Rails component gems moved 7.2.3 → 8.0.5.1 as expected, plus `cgi`
was dropped.

### Why `annotate` did not block

`annotate 2.6.5` (released **2014-06-16**) declares `activerecord (>= 2.3.0)` with **no upper
bound**. Bundler is therefore free to satisfy the graph by walking back nine years to a version that
predates Rails 5 entirely. Only `annotate` 3.x carries the `< 8.0` cap that made it look like a hard
blocker.

**This is worse than a failure, not better.** A failure is loud and forces a decision. A silent
downgrade to a decade-old gem would have shipped quietly and been discovered later — if at all.

### Why `rails-i18n` did not block

Bundler auto-upgraded it to **8.1.0** as part of the same resolution. Both the 8.0 and 8.1 lines
declare `railties (>= 8.0.0, < 9)`, so either satisfies Rails 8.0.5.1 — Bundler simply took the
newest.

**Consequence discovered at T009**: because `rails-i18n` 8.x requires `railties >= 8.0.0`, it
**cannot be installed while Rails is still 7.2.3**. Attempting the pin on its own fails:

```
rails-i18n >= 8.0.0 is incompatible with rails >= 7.2.3, < 8.0.0.beta1.
```

This invalidates the planned sequencing, which assumed both blockers could be cleared *before* the
framework bump. `rails-i18n` and `rails` form an **atomic pair** and must move in the same step —
the same coupling spec 007 hit with `lockbox` and Active Record, in the opposite direction.

**Plan correction**: T008–T010 move from Phase 3 into Phase 4, executed together with T017. Phase 3
retains only the `annotate` → `annotaterb` swap, which genuinely is independent of the Rails
version.

### Conclusion (T007)

The planning-time scan identified the right two gems, but mischaracterised the failure mode. Both
remain in scope and both still require the planned action:

- **`rails-i18n`** — pin to `~> 8.0` explicitly (T008–T010) rather than letting Bundler drift to 8.1.
- **`annotate`** — replace with `annotaterb` (T011–T013). The justification is now *stronger*: the
  alternative is not a failed build but a silent regression to a 2014 gem.

**No third blocker surfaced.** The set is exactly two, as predicted.

**Gate: PASSED** — with the correction recorded above.

## Target framework version (T016)

`bundle lock` resolved to **Rails 8.0.5.1**, matching the version assumed during planning
(research.md R1). Confirmed as the latest 8.0.x. Rails 8.1.3.1 exists and remains deliberately out
of scope.
