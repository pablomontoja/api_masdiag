# Upgrade Record: Rails 7.2.3 → 8.0.5.1

**Feature**: 009-rails-80-upgrade | **Completed**: 2026-08-18 | **Branch**: `009-rails-80-upgrade`

Written for someone who did not perform this upgrade and needs to revert it, continue past it, or
understand why a particular decision was taken (FR-024, SC-017).

---

## What changed

| | Before | After |
|---|---|---|
| Rails | 7.2.3 | **8.0.5.1** |
| Ruby | 3.4.10 | 3.4.10 (unchanged) |
| `load_defaults` | 7.2 | **8.0** |
| Suite | 758 examples, 0 failures | **758 examples, 0 failures** |
| `db/schema.rb` | version `2026_08_14_102700` | **identical** |

### Dependencies

| Gem | Before | After | Why |
|---|---|---|---|
| `rails` | 7.2.3 | 8.0.5.1 | The upgrade. Latest 8.0.x; `.1` is a security release |
| `rails-i18n` | 7.0.10 | 8.0.2 | 7.0.10 caps `railties < 8`. **Pinned `~> 8.0.0`**, not `~> 8.0` — the two-part form permits 8.1.x |
| `annotate` | 3.2.0 | **removed** | Final release; caps `activerecord < 8.0` |
| `annotaterb` | — | 4.24.0 | Maintained fork; replaces the above |
| `cgi` | 0.5.2 | **removed** | Was a `railties`/`actionpack` dependency in 7.2; dropped in 8.0 |
| All `action*`/`active*` | 7.2.3 | 8.0.5.1 | Framework components |

**No other gem moved.** `rspec-rails` stayed 7.1.1, `sentry-*` on 5.x, `alba` 3.10.0, `lockbox`
2.2.0, `solid_queue` 1.4.0, `mission_control-jobs` 1.1.0.

### Files changed

```
Gemfile                                        rails, rails-i18n, annotate→annotaterb
Gemfile.lock                                   regenerated
config/application.rb                          load_defaults 7.2 → 8.0
config/initializers/new_framework_defaults_8_0.rb   added, fully commented out
app/jobs/lalen_api/assign_kit_tests_job.rb     + self.enqueue_after_transaction_commit = true
app/jobs/lalen_api/register_kit_job.rb         + self.enqueue_after_transaction_commit = true
```

Nothing else under `app/`. Nothing under `spec/`, `db/`, or `config/environments/`.

---

## The three things planning got wrong

Recorded because each cost real time and each would cost it again.

### 1. `annotate` does not fail on Rails 8 — it silently downgrades to a 2014 release

The plan expected `bundle lock` to fail naming both blockers. It **succeeded**. Bundler satisfied
the graph by walking `annotate` back from 3.2.0 to **2.6.5**, released **2014-06-16**, which
declares `activerecord (>= 2.3.0)` with no upper bound.

A failure is loud and forces a decision. A silent decade-old downgrade ships quietly. This made the
replacement more urgent, not less. See `annotation-assessment.md`.

### 2. `rails-i18n` cannot be cleared before the bump

The plan treated both blockers as clearable on Rails 7.2.3, with US1 shipping independently.
`rails-i18n` 8.x requires `railties >= 8.0.0`:

```
rails-i18n >= 8.0.0 is incompatible with rails >= 7.2.3, < 8.0.0.beta1.
```

They are an **atomic pair**. T008–T010 moved into Phase 4 and run with the Rails bump. US1 still
shipped independently, but carrying only the annotation swap.

### 3. `enqueue_after_transaction_commit` cannot be set globally in Rails 8.0

The plan (FR-014) called for `config.active_job.enqueue_after_transaction_commit` in
`application.rb`. Reading `activejob-8.0.5.1/lib/active_job/railtie.rb:28-53`:

- The global config is **deprecated in 8.0, removed in 8.1**
- It accepts only `:always`/`:never` — the planned `:default` falls to `else` → **`false`**
- Rails explicitly advises against setting it globally

**What the measurement showed** (under `load_defaults 7.2`, before any change):

```
ActiveJob::Base.enqueue_after_transaction_commit => false
ROLLBACK -> enqueued 1 job     ← the partner would have been notified
```

The framework-level guard **was never active**. Spec 007's protection was one layer — the
code-level fix in `Fv1::KitController` — not the two it was believed to be.

**Fixed** by declaring it per-job on the two jobs that POST to an external partner. After:

```
AssignKitTestsJob: true    ROLLBACK -> 0 jobs    COMMIT -> 1 job    PASS
```

This is the only application code the upgrade changed, against the plan's expectation
(invariant I6). Justified: the alternative was leaving a partner-notification guarantee resting on
one layer while believing it had two. See `defaults-decisions.md`.

---

## What was verified

| Check | Result | Requirement |
|---|---|---|
| Full suite, twice | 758 examples, 0 failures both times | FR-022, SC-004 |
| All 11 namespaces, twice | 436 examples, 0 failures both passes | FR-009, SC-005, SC-013a |
| `git diff spec/` | **Empty** — no assertion weakened | FR-009, invariant I3 |
| Route inventory | **Byte-identical** — no endpoint newly reachable | FR-010, SC-006, I8 |
| `db/schema.rb` | **Identical** to baseline snapshot | FR-020, SC-014, I1 |
| Encryption round-trip | Probe written on 7.2.3 (`ApiAccount` id=15) decrypts on 8.0.5.1 | FR-015, SC-010 |
| Partner notification | Rollback → 0 jobs, commit → 1 job, measured | FR-013, SC-008 |
| Both locales | Zero fallbacks; Polish strings Polish | FR-002, SC-012 |
| `/jobs` dashboard | Renders; **11/11 assets return 200**; 401 unauthenticated and on bad credentials | FR-008a/b, SC-013b |
| Regex sites | All 6; 7 email cases including ReDoS-shaped; **0 timeouts**, slowest 0.018 ms vs 1000 ms budget | FR-017, SC-011 |
| Container image | Builds on `ruby:3.4.10-slim` with Rails 8.0.5.1 | FR-008 |
| Warnings/deprecations | **Zero** | FR-023, SC-015 |

---

## Known gap: the container cannot boot from `docker-compose.yml` as written

`docker compose run app bin/rails runner` fails:

```
admin_controller.rb:4 — Expected name: to be a String, got NilClass (ArgumentError)
```

**This is not an upgrade regression.** Verified: neither `app/controllers/admin_controller.rb` nor
`docker-compose.yml` was touched by this work, and the same configuration fails identically on
Rails 7.2.3.

**Cause**: `.dockerignore` excludes `config/master.key` and `config/credentials/*.key` from the
image — correctly. `docker-compose.yml` supplies `RAILS_MASTER_KEY` only under `build.args` (line
9–11), never under `environment` (line 17–20). The container runs with `RAILS_ENV=production` and no
way to decrypt credentials, so `credentials.dig(:mission_control, …)` returns `nil` and
`AdminController` raises during eager loading.

Rails 8.0 does not cause this; it was already failing. `http_basic_authenticate_with` simply raises
a clear `ArgumentError` on `nil` rather than failing more obscurely later.

**Fix** (outside this upgrade's scope — it changes deployment configuration):

```yaml
    environment:
      RAILS_ENV: production
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}   # supply via a gitignored .env
```

The image itself is verified good: it builds, and the failure is purely credential availability.

---

## Deferred, with reasons

| Item | Why |
|---|---|
| **Annotation regeneration** | `annotaterb` rewrites **73 files** (818+/319−), reorders columns alphabetically, adds Indexes/Foreign Keys sections, and annotates 22 factories + 7 specs the old gem never touched. A reasonable standalone commit; not one to fold into a framework upgrade |
| **Rails 8.1** | Real and current (8.1.3.1). Two minors at once conflates two sets of breaking changes. Candidate for spec 010 — note `rails-i18n` is pinned `~> 8.0.0` and must move with it |
| **`factory_bot` 4.11 → 6.x** | Deferred from spec 008; still the change that would retire the `observer` declaration in `Gemfile` |
| **Active Storage migrations** | `app:update` generated three (`add_service_name_to_active_storage_blobs`, `create_active_storage_variant_records`, `remove_not_null_on_active_storage_blobs_checksum`). **Deleted.** They date from Active Storage 6.0/6.1 and have never been applied here. They alter shared `LabSample` tables that nine applications read — needs explicit confirmation and its own risk assessment |
| **`params.expect` migration** | 25 `params.require` sites work unchanged; a refactor with its own risk |
| **`db/schema.rb` regeneration** | Rails 8.0 sorts columns alphabetically. Not run: in spec 007 a dump from a stale development database silently deleted two table definitions and regressed the migration version |
| **`docker-compose.yml` runtime key** | See the gap above — deployment configuration, not a framework change |

---

## How to revert

Revert the framework **and** the dependent code **together**. Spec 007 reverted only the lockfile,
left newer code in place, and produced 13 failures that masked the real state.

```bash
# Two commits: the framework bump and, before it, the annotate swap.
git revert --no-commit c368204          # Rails 8.0.5.1 bump
git revert --no-commit 5e7fd80          # annotate → annotaterb  (optional; see below)
bundle install
bundle exec rspec                       # must reproduce: 758 examples, 0 failures
```

Or from a clean branch point:

```bash
git checkout 61a22f89a67bacd4fd7f5555a0b73431350d023f -- \
  Gemfile Gemfile.lock config/application.rb \
  app/jobs/lalen_api/assign_kit_tests_job.rb \
  app/jobs/lalen_api/register_kit_job.rb
rm -f config/initializers/new_framework_defaults_8_0.rb
bundle install
bundle exec rspec
```

**Baseline to reproduce**: 758 examples, 0 failures, Rails 7.2.3, Ruby 3.4.10, schema version
`2026_08_14_102700`.

### The revert procedure was executed, not just written (T055)

The second form above was run end to end: files restored from `61a22f8`, the defaults initializer
removed, `bundle install`, full suite. Result — **Rails 7.2.3, 758 examples, 0 failures**: the
baseline reproduced exactly (SC-016). The upgraded state was then restored and re-verified (Rails
8.0.5.1, 758 examples, 0 failures, both job guards `true`, `git diff spec/` empty, schema identical).

A revert procedure that has never been run is a hypothesis. This one is tested.

**Do not revert the `annotate` swap on its own** while staying on Rails 8 — `annotate` 3.2.0 caps
`activerecord < 8.0`, and Bundler will resolve to the 2014 release rather than fail. If reverting
the framework too, reverting the swap is safe but unnecessary: `annotaterb` works fine on 7.2.3.

**The encryption probe** (`ApiAccount` `enc_probe_009`, id=15) is test data created for FR-015. Safe
to delete once the upgrade is accepted; keep it if a further version bump is planned, since it is
the only record proving cross-version decryption.

---

## Commits

| SHA | Subject |
|---|---|
| `5e7fd80` | Replace annotate with annotaterb; add spec 009 for Rails 8.0 upgrade |
| `c368204` | Upgrade Rails 7.2.3 to 8.0.5.1 |
| *(this one)* | Adopt Rails 8.0 framework defaults |
