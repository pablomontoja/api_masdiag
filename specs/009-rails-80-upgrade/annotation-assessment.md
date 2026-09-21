# Annotation Assessment: `annotate` → `annotaterb`

**Feature**: 009-rails-80-upgrade | **Task**: T013 | **Date**: 2026-08-18

## Decision

**Swap the gem. Do not commit the regeneration.**

`annotate` is replaced by `annotaterb` in the `Gemfile` (T011–T012), which is what unblocks Rails 8.
Annotations themselves are **left exactly as `annotate` wrote them**. The 39 models that carry
schema comments keep the blocks they have; no file under `app/models/` or `spec/` is modified.

## Why the gem had to be replaced

`annotate` 3.2.0 is the final release of that gem and declares `activerecord (>= 3.2, < 8.0)`.

The planning phase expected this to block resolution outright. It does not — and the real behaviour
is worse. With `annotate` left in place and Rails raised to 8.0, Bundler **silently resolves back to
`annotate` 2.6.5**, released **2014-06-16**, which declares `activerecord (>= 2.3.0)` with no upper
bound. A decade-old gem satisfying a modern graph is a quiet regression that would have shipped
unnoticed. Replacement is therefore not optional cleanup; it is the only way to avoid the downgrade.

## Why the regeneration was rejected

Running `bundle exec annotaterb models` on a clean tree produced:

| Measure | Value |
|---|---|
| Files rewritten | **73** |
| Diff | **818 insertions, 319 deletions** across 44 files |
| Models annotated | 43 (vs 39 previously annotated) |
| **Factories annotated** | **22** — `annotate` never touched these |
| **Model specs annotated** | **7** — likewise new |

The format differs substantially. For `app/models/api_account.rb`:

- **Columns reordered** — `annotaterb` sorts alphabetically within groups; `annotate` preserved
  database order
- **`# Database name: primary` added** — new line reflecting the multi-database setup
- **`# Indexes` section added** — `fk_rails_8f4a850bff (contractor_id)`
- **`# Foreign Keys` section added** — `(contractor_id => Contractors.Id)`

None of this is *wrong*. It is simply a different, more verbose convention, and adopting it means a
73-file diff landing in the middle of a framework upgrade whose central discipline is that
application files stay untouched (invariant I6) and that the upgrade's real changes remain legible.

Research R3 anticipated exactly this and set the rule in advance: generate to a scratch state, diff,
and only commit if blocks are semantically equivalent. They are not — so the regeneration was
reverted with `git checkout app/models/ spec/factories/ spec/models/`.

## Consequences

**Now**: annotations are stale relative to what `annotaterb` would generate, but they are exactly as
stale as they were before this upgrade began. Nothing regressed. The gem is dev-tooling only
(`:development, :test` group) and cannot affect runtime behaviour — which is what made deferring
safe.

**Later**: whoever next runs `annotaterb models` gets the 73-file reformat in one go. That is a
reasonable standalone commit — mechanical, reviewable, and unentangled from a framework upgrade. It
should not be folded into this one.

**Not attempted**: tuning `annotaterb` via a `.annotaterb.yml` to reproduce the old format. The
application has never had an annotation config file (the old gem ran on pure defaults), and adding
one to make a dev-tooling diff smaller is not work this upgrade needs to do.

## Verification

```
$ git status --porcelain | grep -vE "specs/009|\.specify|CLAUDE.md"
 M Gemfile
 M Gemfile.lock
```

Only the dependency manifests changed. Rails remains 7.2.3 at this point; the lockfile diff is
confined to `annotate 3.2.0` → `annotaterb 4.24.0` with no other gem movement (FR-004).
