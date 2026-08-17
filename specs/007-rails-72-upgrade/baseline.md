# Baseline Record — Pre-Upgrade State

**Feature**: 007-rails-72-upgrade | **Captured**: 2026-08-17
**Tasks**: T001, T002, T003, T004

This is the reference every later verification compares against (FR-001). Reverting to this state must reproduce these results exactly (FR-028, SC-015).

## Test suite (T001)

| Metric | Value |
|--------|-------|
| Examples | **737** |
| Failures | **0** |
| Runtime | **38.87s** (files took 2.49s to load) |
| Command | `bundle exec rspec` under `rvm use 3.3.7` |

**Gate**: PASSED — suite is green.

> Note: the spec quotes ~36s from an earlier run; 38.87s here is the same suite on a differently-loaded machine. The SC-017 ceiling (+50%) is therefore **≤58.3s** measured from this baseline.

## Version state (T003)

| Property | Value | Source |
|----------|-------|--------|
| Rails | **7.1.6** | `Gemfile.lock` |
| Ruby | **3.3.7p123** | `Gemfile.lock` RUBY VERSION |
| `config.load_defaults` | **7.1** | `config/application.rb:24` |

## Git state (T002)

| Property | Value |
|----------|-------|
| Branch | `007-rails-72-upgrade` |
| HEAD | `d389a4f9b10d4a4696943209d9fd087a8881eff8` |
| Lockfile snapshot | `specs/007-rails-72-upgrade/baseline-Gemfile.lock` |
| Lockfile sha256 (first 16) | `0fd2e0c9174e2751` |

## Ruby version pin consistency (T004)

All four declarations agree — invariant holds (FR-010, FR-011, SC-005):

| Location | Value |
|----------|-------|
| `.ruby-version` | `ruby-3.3.7` |
| `Gemfile` | `ruby "3.3.7"` |
| `Dockerfile` | `ARG RUBY_VERSION=3.3.7` |
| `Gemfile.lock` | `ruby 3.3.7p123` |

**Gate**: PASSED — no drift. This must still hold at T059.

## Revert procedure

```bash
git checkout main -- Gemfile Gemfile.lock
bundle install
bundle exec rspec        # must yield 737 examples, 0 failures
```
