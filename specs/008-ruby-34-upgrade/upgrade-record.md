# Ruby 3.4 Upgrade — Handover Record

**Feature**: 008-ruby-34-upgrade | **Completed**: 2026-08-17 | **Branch**: `008-ruby-34-upgrade`
**Task**: T044 | **Satisfies**: FR-020, SC-014

Written so another developer can act on this without reading the diff.

---

## What changed

`api_masdiag` moved from **Ruby 3.3.7 to 3.4.10**, with Rails unchanged at 7.2.3 and
`load_defaults` unchanged at 7.2.

Three commits, each independently revertible:

| Commit | What | Ships alone? |
|--------|------|--------------|
| `1a555fa` | Declare `observer` as an explicit dependency | ✅ yes |
| `fe7b609` | Add encryption round-trip spec | ✅ yes |
| `e4f2edd` | Upgrade Ruby 3.3.7 → 3.4.10 | depends on the above |

The first two landed **on Ruby 3.3.7** and are useful regardless of whether the runtime moved.

### Files touched

Four, plus one new spec. **Zero application code changes.**

```
Gemfile          + gem "observer";  ruby "3.3.7" → "3.4.10"
Gemfile.lock     + observer (0.1.2);  RUBY VERSION 3.3.7p123 → 3.4.10p104
.ruby-version    ruby-3.3.7 → ruby-3.4.10
Dockerfile       ARG RUBY_VERSION=3.3.7 → 3.4.10
spec/models/encryption_round_trip_spec.rb   (new)
```

---

## What was verified

| Check | Result |
|-------|--------|
| Test suite | **758 examples, 0 failures** (755 baseline + 3 new) |
| Warnings | **0** deprecations, **0** stdlib warnings |
| API namespaces | **8 of 8** unchanged |
| LabSample schema | **untouched** — a runtime change does not restamp the dump |
| Source-compiled gems | all **11** resolved |
| Precompiled gems | `ffi`, `nokogiri` resolved native `x86_64-linux-gnu` binaries |
| Lockfile containment | **one line** changed — the `RUBY VERSION` stanza |
| Cross-runtime encryption | data written on 3.3.7 decrypts on 3.4.10 |
| Job semantics | post-commit enqueue preserved, verified on a real worker |
| Container image | builds on `ruby:3.4.10-slim`; Rails 7.2.3 loads inside it |
| Suite runtime | 38.95s vs 35.92s baseline (ceiling 53.9s) |
| Revert | baseline reproduces exactly |

Supporting detail: `baseline.md`, `stdlib-audit.md`, `equivalence-report.md`,
`factory-bot-assessment.md`.

---

## Four findings worth knowing

### 1. Target was 3.4.10, not the trial's 3.4.9

The sandbox trial that preceded this work ran on 3.4.9. By execution time **3.4.10 had published**,
so the plan re-targeted it rather than inheriting the trial's version. RVM's known-list was stale
and needed `rvm get stable` before `rvm install 3.4.10` would work — a real prerequisite, easily
missed.

### 2. `observer` was the only blocker — and now that is *proven*, not just observed

The trial observed the symptom: 97 load errors, all from `observer`. The audit here established
*why* it is the only one. A stdlib component breaks the build only when **all three** hold:

- required by loaded code,
- absent from the lockfile,
- no longer bundled by the runtime.

`ostruct` and `drb` are also required by installed gems (`json`, `oj`, `activesupport`, `rspec-core`,
`minitest`) but already resolve from the lockfile, so Bundler supplies them. Only `observer` failed
all three tests.

**Watch out**: an early scan reported `syslog` as a second blocker. It is commented out in
`config/environments/staging.rb:75`. Scans of this kind must exclude comment lines or they
manufacture work.

### 3. The lockfile diff was a single line

`bundle install` — **never `bundle update`** — produced exactly:

```diff
-   ruby 3.3.7p123
+   ruby 3.4.10p104
```

Zero gem version movement. The sandbox trial had used an unconstrained update and swept in ~20
unrelated upgrades (`alba`, `oj`, `rack`, `aws-sdk-s3`…), which is the trap spec 007 also hit.

### 4. Cross-runtime encryption needed a probe record, not a spec

`ApiAccount#settings` is Lockbox-encrypted. The suite runs entirely on one runtime, so **no spec can
demonstrate** that data written on 3.3.7 decrypts on 3.4.10. A record was persisted before the change
and read back after:

```
reading on Ruby:   3.4.10
decrypted:         {probe: "pre-ruby-34", written_on: "3.3.7"}
ciphertext opaque: true
```

The probe record has since been removed from the development database.

---

## What was deferred

| Item | Why | Revisit when |
|------|-----|--------------|
| **`factory_bot` 4.11 → 6.x** | Would retire the `observer` shim (6.x replaced stdlib `Observer` with its own `CallbacksObserver`), but spans 2 major versions across **1068 call sites**. Encouragingly, none of the classic 4.x→6.x breakages are present — 0 static attributes, 0 `FactoryGirl`, 0 `ignore`. See `factory-bot-assessment.md`. | Own spec, sequenced 4.11 → 5.x → 6.x |
| **staging/production boot** | DB host unreachable from this workstation, identical on 3.3.7. Inherited from spec 007. | **Before release** — needs a host with database access |
| **CI** | None exists; all verification was local plus a container build | Raised independently against spec 007 |

---

## ⚠️ Before release

**staging and production boot remain unverified.** Both resolve their database host from credentials,
and that host refuses connections from the development workstation. The container image builds and
Rails loads inside it (FR-014 satisfied), but a full application boot under staging/production
settings still needs a host with database access.

This is the one gate this feature could not close, and it is the same one spec 007 left open.

---

## How to revert — tested, not assumed

```bash
rvm use 3.3.7
git checkout fe7b609 -- Gemfile Gemfile.lock .ruby-version Dockerfile
bundle install
bundle exec rspec        # yields 758 examples, 0 failures
```

**Exercised during T043**: reverting to the pre-runtime commit reproduced the baseline exactly, with
no broken intermediate state. This differs from spec 007, where reverting only the lockfile left a
tree that failed 13 examples — there, the code depended on a newer framework API. Here nothing does,
which is why the revert is clean.

To keep `observer` while dropping only the runtime move, revert `e4f2edd` alone.

The pre-change lockfile is preserved at `specs/008-ruby-34-upgrade/baseline-Gemfile.lock`
(sha256 prefix `cec5f9754bc4c5bf`).
