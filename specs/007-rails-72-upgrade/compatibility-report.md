# Dependency Compatibility Report

**Feature**: 007-rails-72-upgrade | **Date**: 2026-08-17
**Tasks**: T047–T050 | **Satisfies**: FR-002, FR-003, FR-004, FR-005, FR-006, SC-001, SC-002

## Verdict: no blocking dependency

The upgrade was viable. Determined by **resolving the dependency graph** against
Rails 7.2.3 rather than consulting compatibility tables — the resolution either
succeeds or it does not, which is authoritative in a way a third-party matrix is not.

## Summary (SC-001)

| Verdict | Count | Gems |
|---------|-------|------|
| **needs-bump (framework)** | 13 | `rails`, `railties`, `activerecord`, `activesupport`, `actionpack`, `actionmailer`, `actionview`, `activejob`, `activemodel`, `activestorage`, `actioncable`, `actionmailbox`, `actiontext` — all `7.1.6` → `7.2.3` |
| **needs-bump (forced)** | 1 | `lockbox` `1.2.0` → `2.2.0` |
| **needs-declaration** | 2 | `csv` (new, `3.3.6`), `base64` (`0.3.0`, was transitive) |
| **new transitive** | 1 | `useragent` `0.16.11` |
| **removed transitive** | 1 | `mutex_m` `0.3.0` |
| **compatible, unchanged** | ~146 | everything else, held by the conservative update |
| **blocking** | **0** | — |

Total gems in lockfile: 164 after upgrade (was 165 before `csv` added / `mutex_m` removed).

## The `lockbox` pin: not lifted, inverted (FR-004)

The `Gemfile` carried:

```ruby
# Lockbox >= 2.2 refuses to load on Active Record 7.1
gem "lockbox", "~> 1.2.0"
```

Reading the gem source (`lockbox-2.2.0/lib/lockbox.rb:98–113`) shows the real gate:

```ruby
ActiveSupport.on_load(:active_record) do
  ar_version = ActiveRecord::VERSION::STRING.to_f
  if ar_version < 7.2
    if ar_version >= 7.1
      raise Lockbox::Error, "Active Record #{...} requires Lockbox < 2.2"
```

The condition is `ar_version < 7.2`. **Lockbox 2.2.0 requires Active Record ≥ 7.2.**

So the constraint did not merely become liftable on 7.2 — it **reversed**. 2.2.0 was
unusable before this upgrade and is the correct version after it. The two versions
have disjoint supported ranges, which is why the Rails bump and the lockbox bump had
to land in a single commit rather than as separate steps.

The obsolete comment has been replaced with one stating the real constraint.

**Verified**: encrypted attributes round-trip correctly under Lockbox 2.2.0 / AR 7.2.3
(see `equivalence-report.md` T036). This mattered because Lockbox protects patient
data, so a green suite alone was not sufficient evidence.

## The git-sourced gem (FR-003)

`k-php-serialize`, sourced from `github.com/pablomontoja/php-serialize`, cannot be
assessed by automated compatibility services (RailsBump and similar index RubyGems
only). The spec required it be flagged for manual verification rather than assumed
compatible.

**Result**: it **resolved cleanly** in the Rails 7.2.3 dependency graph and the full
suite passes with it loaded. No action required.

## Method note: why resolution beat per-gem queries

Per-gem `gem dependency --remote` queries were attempted first and abandoned:
they were slow, rate-limited, and misleading — several gems report "no rails
dependency" because they constrain `railties` transitively or declare no runtime
dependency at all (`lockbox` among them, which is precisely why its constraint is
enforced by a runtime guard instead).

Resolving the actual graph answered the question definitively in one step, and also
surfaced the update-scope problem below, which a per-gem survey would have missed.

## Update containment (FR-028)

An unconstrained `bundle lock --update` resolves successfully — which is the trap.
It also moves roughly 40 unrelated gems:

| Gem | Current | Unconstrained | Nature |
|-----|---------|---------------|--------|
| `rspec-rails` | 7.1.1 | 8.0.4 | **major** |
| `sentry-ruby` / `sentry-rails` | 6.6.2 | 6.7.0 | minor |
| `solid_queue` | 1.4.0 | 1.6.0 | minor, job backend |
| `rack` | 3.2.6 | 3.2.7 | patch |
| `alba`, `oj`, `aws-sdk-s3`, `bootsnap`, … | — | newer | assorted |

Any failure would have been unattributable, and the revert guarantee (FR-028) lost.

**Used instead**: `bundle lock --conservative --update rails lockbox`, which produced
exactly the intended diff and nothing more. Confirmed post-upgrade that `rspec-rails`
is still 7.1.1, `solid_queue` still 1.4.0, sentry still 6.6.2.

## Breaking-change coverage (FR-005, SC-002)

All 12 documented 7.1→7.2 changes were audited at planning time and **re-verified at
execution time** (see `audit-verification.md`). Final status:

| Status | Count | Changes |
|--------|-------|---------|
| Not applicable | 6 | #3 params comparison, #5 secrets, #6 `check_pending!`, #9 `query_constraints`, #10 mailer `args:`, #12 `alias_attribute` |
| Already compliant | 2 | #2 `show_exceptions` (already `:rescuable`), #8 `fixture_path` (factories only) |
| **Remediated** | 3 | #4 `AR.connection` → `with_connection` (3 sites), #7 `serialize` coder keyword (1 site), #11 queue adapter (verified, no change needed) |
| **Remediated (behavioural)** | 1 | #1 transaction-aware enqueuing — partner notification moved outside the transaction |

Zero changes remain unaddressed.

## Blocked-upgrade path (FR-006)

Not triggered. FR-006 required reporting the upgrade as blocked if any dependency had
no 7.2-compatible release. No such dependency exists, so this path is recorded as
**not applicable** rather than unmet.
