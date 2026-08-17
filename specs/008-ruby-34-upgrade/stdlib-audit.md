# Standard Library Dependency Audit

**Feature**: 008-ruby-34-upgrade | **Verified**: 2026-08-17
**Tasks**: T005, T006, T007 | **Satisfies**: FR-001, FR-002, SC-001

FR-002 required re-scanning rather than trusting the sandbox trial's conclusion. The scan was
**broader than the trial** — it covered project code *and* all 164 installed gems — and confirms the
trial's finding while adding useful negative results.

## T005 — Project code

Scanned `app/`, `lib/`, `config/`, `spec/` for `require` of components removed from Ruby 3.4's
default gems. **Comment lines excluded** (see false positive below).

| Component | Active requires | Declared in Gemfile | Status |
|-----------|-----------------|---------------------|--------|
| `csv` | 6 | ✅ | already-declared (spec 007) |
| `base64` | 1 | ✅ | already-declared (spec 007) |
| `observer` | 0 | ❌ | not required by project code |
| `ostruct`, `bigdecimal`, `drb`, `logger`, `benchmark`, `mutex_m`, `abbrev`, `syslog`, `getoptlong`, `nkf`, `fiddle` | 0 | — | confirmed-unused |

### False positive worth recording

An initial scan reported **`syslog` with 1 require**, which would have been a new blocker. It is
commented out:

```ruby
# config/environments/staging.rb:75
  # require "syslog/logger"
```

The first grep did not exclude comment lines. Verified that `syslog` genuinely fails to load on Ruby
3.4.9 (`cannot load such file -- syslog`), so had this been an *active* require it would have been a
real second blocker. It is not.

**Lesson**: scans of this kind must exclude comments, or they manufacture work.

## T006 — Installed gems (the scan that matters)

Project code is not where the blocker lives — it lives in a dependency. Scanned the `lib/` directory
of all **164 installed gems** for internal requires of removed default gems.

| Component | Required by | In lockfile | Loads on 3.4.9 | Verdict |
|-----------|-------------|-------------|----------------|---------|
| **`observer`** | `drb-2.2.3`, **`factory_bot-4.11.1`** | ❌ **no** | ❌ **LOADERROR** | **NEEDS DECLARATION** |
| `ostruct` | `json`, `oj`, `ostruct`, `shoulda-callback-matchers` | ✅ yes | ✅ LOADED | no action — resolves as a gem |
| `drb` | `activesupport`, `drb`, `minitest`, `rspec-core` | ✅ yes | ✅ LOADED | no action — resolves as a gem |
| `mutex_m`, `abbrev`, `syslog`, `getoptlong` | none | — | — | confirmed-unused |

**Why only `observer` fails**: a component breaks the build only when all three conditions hold —
required by loaded code, absent from the lockfile, and no longer bundled by the runtime. `ostruct`
and `drb` satisfy the first condition but are already present as resolved gems, so Bundler supplies
them.

This is a stronger result than the trial produced. The trial observed the *symptom* (97 load errors,
all from `observer`); this audit establishes *why* it is the only one, and confirms no second blocker
is waiting behind it.

## T007 — E2 finding table

Per the `data-model.md` E2 schema:

| Component | Required by | Declared | Status |
|-----------|-------------|----------|--------|
| `csv` | 6 project files | ✅ | `already-declared` |
| `base64` | `ScannedDocs::OcrClient` | ✅ | `already-declared` |
| **`observer`** | `factory_bot-4.11.1/lib/factory_bot/evaluation.rb:1`, `drb-2.2.3` | ❌ | **`needs-declaration`** |
| `ostruct` | 4 gems | via lockfile | `confirmed-unused` (as a *declaration*; resolves transitively) |
| `drb` | 4 gems | via lockfile | `confirmed-unused` (as a *declaration*; resolves transitively) |
| `bigdecimal`, `logger`, `benchmark`, `mutex_m`, `abbrev`, `syslog`, `getoptlong`, `nkf`, `fiddle` | none | — | `confirmed-unused` |

## Verdict

**Exactly one declaration required: `observer`.** The trial's conclusion is confirmed by a broader
method, and two candidates that could plausibly have been blockers (`ostruct`, `drb`) are positively
ruled out rather than merely unobserved.

**Gate**: PASSED — user story work may proceed.
