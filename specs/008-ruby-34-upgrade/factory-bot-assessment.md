# factory_bot Upgrade Assessment

**Feature**: 008-ruby-34-upgrade | **Assessed**: 2026-08-17
**Tasks**: T036–T038 | **Satisfies**: FR-017, FR-018

## Why this assessment exists

Ruby 3.4 removed `observer` from the default gems, and `factory_bot 4.11.1` requires it
unconditionally. Declaring `gem "observer"` unblocked the upgrade in one line — but a compatibility
shim declared without recording *why* it exists is how such shims become permanent and unexplained.

FR-017 requires an upgrade-or-defer decision. This is it.

## Current state

| Package | Installed | Latest | Gap |
|---------|-----------|--------|-----|
| `factory_bot` | 4.11.1 | 6.6.0 | 2 major versions |
| `factory_bot_rails` | 4.11.1 | 6.5.1 | 2 major versions |

Declared in `Gemfile:66` as `gem 'factory_bot_rails', '~> 4.8', '>= 4.8.2'`.

## Would upgrading actually retire the shim?

**Yes.** Verified against the 6.5.6 source: `factory_bot` no longer requires the standard library
`observer` at all. It was replaced with an internal implementation:

```ruby
# factory_bot-6.5.6/lib/factory_bot/callbacks_observer.rb:3
class CallbacksObserver
```

```bash
grep -rn "require ['\"]observer['\"]" factory_bot-6.5.6/lib/   # → no matches
```

So the upgrade genuinely removes the need for the declaration, rather than merely moving the problem.

## Blast radius

| Measure | Count |
|---------|-------|
| Factory definition files | 25 |
| `create` / `build` / `build_stubbed` / `attributes_for` call sites | **1068** |
| Attribute blocks across factories | 211 |

## Breaking-change exposure — lower than the version gap suggests

The classic 4.x → 6.x breakages were checked against this codebase and **none are present**:

| Breaking change | Occurrences here |
|-----------------|------------------|
| Static attributes without a block (removed in 5.0) | **0** |
| `FactoryGirl` constant (renamed in 4.9) | **0** |
| `ignore` → `transient` (renamed in 4.x) | **0** |

The factories already use the modern block syntax throughout, which is the single largest source of
4.x → 5.x breakage. That materially lowers the risk — but does not eliminate it, since 1068 call
sites remain unexercised against the newer library until the upgrade is attempted.

## Decision: **DEFER**

**Rationale:**

1. **Not required.** The `observer` declaration is a one-line, zero-behaviour-change alternative that
   is already shipped and verified. The upgrade buys tidiness, not capability.
2. **Wrong feature.** This spec is a runtime upgrade with a deliberately empty Complexity Tracking
   table and no application code changes. Folding in a two-major-version test-library upgrade —
   touching 1068 call sites — would violate the attribution principle that both this feature and
   spec 007 are built around.
3. **Test-infrastructure risk is asymmetric.** A subtle factory behaviour change (e.g. in callback
   ordering or `build_stubbed` semantics) can make specs pass while testing the wrong thing. That
   deserves its own verification pass, not a corner of a runtime upgrade.
4. **No deadline.** `observer` is a maintained gem and the declaration costs nothing operationally.

**Recommended when pursued**: its own spec, sequenced 4.11 → 5.x → 6.x rather than in one jump, with
the suite green at each step.

## FR-018 — Removal condition recorded

The `Gemfile` declaration states what would retire it:

```ruby
gem "observer" # required by factory_bot 4.11; removable once factory_bot moves past 4.x
```

**Revisit trigger**: any `factory_bot` upgrade past 4.x. At that point `gem "observer"` should be
removed and the suite re-run to confirm nothing else pulls the stdlib component — noting that `drb`
also requires it, though `drb` resolves from the lockfile independently (see `stdlib-audit.md`).
