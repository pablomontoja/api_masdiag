# Warnings and Deprecations

**Feature**: 009-rails-80-upgrade | **Task**: T051 | **Date**: 2026-08-18

FR-023 requires each warning emitted after the upgrade be resolved or recorded with a rationale.

## Result: zero outstanding

```bash
$ bundle exec rspec 2>&1 | grep -iE "warning|deprecat"
    has the correct subject and includes the return-at-expense warning
    logs a warning when errors are present
    records warnings for unmapped OBX codes
```

All three matches are **spec description text** containing the word "warning" — they are test names,
not emitted warnings. The suite produces no deprecation or warning output on Rails 8.0.5.1 with
`load_defaults 8.0`.

Boot is likewise clean:

```bash
$ bin/rails runner 'puts "boot ok"' 2>&1 | grep -i deprecat
(no output)
```

## The one deprecation that appeared, and how it was resolved

Immediately after the framework bump, with defaults still at 7.2, booting emitted:

```
DEPRECATION WARNING: `to_time` will always preserve the full timezone rather than offset
of the receiver in Rails 8.1. To opt in to the new behavior, set
`config.active_support.to_time_preserves_timezone = :zone`.
```

**Resolved by adopting `load_defaults 8.0`**, which sets `to_time_preserves_timezone = :zone`. This
is a good illustration of why the phases were separated: the warning appeared in the window between
bumping the framework and adopting its defaults, and closed when the defaults were adopted. Verified
afterwards — the warning no longer appears at boot or during the suite.

## Deprecation deliberately avoided

Rails 8.0 deprecates `config.active_job.enqueue_after_transaction_commit` (removed in 8.1). Setting
it would have emitted:

```
`config.active_job.enqueue_after_transaction_commit` is deprecated and will be removed in
Rails 8.1. This configuration can still be set on individual jobs using
`self.enqueue_after_transaction_commit=`, but due the nature of this behavior, it is not
recommended to be set globally.
```

The plan (FR-014) originally called for setting exactly this. It was **not** set; the per-job
mechanism was used instead. See `defaults-decisions.md`. So the count of zero warnings reflects a
decision, not an absence of the underlying concern.

## Note on `Rails.application.deprecators.behavior = :raise`

The source upgrade guide suggests raising on deprecations in tests. Not adopted here: the suite
emits none, so the setting would change nothing today, and enabling it is a testing-policy change
rather than part of a framework bump. Worth considering for spec 010, where it would catch Rails
8.1 deprecations early.
