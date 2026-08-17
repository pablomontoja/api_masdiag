# Baseline Record — Pre-Change State

**Feature**: 008-ruby-34-upgrade | **Captured**: 2026-08-17
**Tasks**: T001–T004 | **Satisfies**: FR-013, SC-007

The reference every later verification compares against. Reverting to this state must reproduce
these results exactly (FR-016, SC-012).

## Test suite (T001)

| Metric | Value |
|--------|-------|
| Examples | **755** |
| Failures | **0** |
| Runtime | **35.92s** (files took 9.03s to load) |
| Command | `bundle exec rspec` under `rvm use 3.3.7` |

**Gate**: PASSED — suite green.

SC-013 ceiling (+50% of 35.92s) = **53.9s**.

## Git state (T002)

| Property | Value |
|----------|-------|
| Branch | `008-ruby-34-upgrade` |
| HEAD | `0df1effec4c569679e58195ceac469c5ab4b74be` |
| Lockfile snapshot | `specs/008-ruby-34-upgrade/baseline-Gemfile.lock` |
| Lockfile sha256 (first 16) | `cec5f9754bc4c5bf` |

## Ruby version pins (T003)

All four sources agree — the invariant that must still hold after the change (FR-005, SC-006):

| Location | Value |
|----------|-------|
| `.ruby-version` | `ruby-3.3.7` |
| `Gemfile:4` | `ruby "3.3.7"` |
| `Dockerfile:4` | `ARG RUBY_VERSION=3.3.7` |
| `Gemfile.lock` RUBY VERSION | `ruby 3.3.7p123` |

**Target**: all four become `3.4.10`.

## Framework state — MUST NOT CHANGE (T004)

| Property | Value | Requirement |
|----------|-------|-------------|
| Rails | **7.2.3** | FR-013, SC-007 |
| `config.load_defaults` | **7.2** | FR-013, SC-007 |

This feature changes the language runtime only. Any movement in either value means the change has
exceeded its scope.

## Encryption probe (T015)

A record persisted **on Ruby 3.3.7** whose ciphertext must decrypt after the runtime change. This is
the only way to prove *cross-runtime* compatibility — the suite runs entirely on one runtime at a
time, so no spec can express it.

| Property | Value |
|----------|-------|
| Model | `ApiAccount` (`has_encrypted :settings, type: :hash`) |
| `username` | `enc_probe_008` |
| Record id | **14** |
| Written on | Ruby **3.3.7** |
| Payload | `{ probe: "pre-ruby-34", written_on: "3.3.7" }` |
| Database | development |

**Verification after the change** (T030): read record 14 on Ruby 3.4.10 and confirm the payload
decrypts unchanged and the ciphertext never contains the plaintext.

**Cleanup**: remove this record once verification is complete (T045).

## Revert procedure

```bash
rvm use 3.3.7
git checkout main -- Gemfile Gemfile.lock .ruby-version Dockerfile
bundle install
bundle exec rspec        # must yield 755 examples, 0 failures
```

Revert the runtime **and** the files together — spec 007 demonstrated that reverting only the
lockfile leaves a broken tree.
