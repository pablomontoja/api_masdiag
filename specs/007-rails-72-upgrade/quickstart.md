# Quickstart: Executing the Rails 7.2 Upgrade

**Feature**: 007-rails-72-upgrade | **Date**: 2026-08-17

Twelve steps, each a separate commit with its own gate. **If a gate fails, stop and revert that step** — do not proceed with a partial state. Steps 1–6 run on Rails 7.1 and are valuable even if the upgrade is abandoned.

All commands assume `rvm use 3.3.7` (per `CLAUDE.md`).

---

## Steps 1–2 · Baseline and audit (User Story 1, P1)

### 1. Record the baseline

```bash
rvm use 3.3.7
bundle exec rspec 2>&1 | tail -5          # expect: 737 examples, 0 failures, ~36s
cp Gemfile.lock /tmp/baseline-Gemfile.lock
git rev-parse HEAD                         # record the commit
```

Record: example count, failure count, runtime, Rails version, Ruby version, lockfile copy.

**Gate**: suite green; a rerun reproduces the same outcome.

> If the suite is *not* green before you start, stop. Every later comparison depends on this reference.

### 2. Re-verify the Breaking-Change Audit

The audit in `spec.md` was taken 2026-08-17; line numbers drift. Re-run the scans:

```bash
grep -rn "alias_attribute" app/ lib/ config/                      # expect: none
grep -rn "show_exceptions" config/                                # expect: only test.rb, :rescuable
grep -rn "Rails.application.secrets" app/ lib/ config/            # expect: none
grep -rn "check_pending" spec/ config/ lib/                       # expect: none
grep -rn "query_constraints" app/ lib/                            # expect: none
grep -rnE "^\s*serialize " app/models/                            # expect: 1 positional site
grep -rn "ActiveRecord::Base.connection" app/ lib/ db/ spec/      # expect: 3 sites
```

Then re-confirm the in-transaction enqueue — the one that matters:

```bash
for f in $(grep -rl "perform_later\|deliver_later" app/ lib/); do
  grep -q "transaction do\|transaction(" "$f" && echo "$f"
done
```

**Gate**: every audit entry confirmed or corrected. Any *new* in-transaction enqueue must be added to the E4 decision record before continuing.

---

## Step 3 · Declare `csv` and `base64` (User Story 2, P1)

Still on Rails 7.1. Add to `Gemfile`:

```ruby
gem "csv"      # required by 6 recurring mailers/services; not a Ruby default gem from 3.4
gem "base64"   # required by ScannedDocs::OcrClient; not a Ruby default gem from 3.4
```

```bash
bundle lock        # plain resolution — NOT --conservative, which cannot add new gems
git diff Gemfile.lock
```

**Gate**: the lockfile diff adds **only** `csv (3.3.6)`. `base64` was already present transitively. Rails must remain 7.1.6. Then:

```bash
bundle exec rspec
```

**Gate**: suite green. Commit — this ships independently of the upgrade.

---

## Step 4 · `regspec` smoke checks (must precede the bump)

Create `spec/requests/regspec/` covering the seven write endpoints (see `contracts/api-equivalence.md`). All `include MasdiagCheck`, so use an `ApiAccount` with `institution_id == 1` via `http_auth_header`.

Per endpoint: one success path, one auth-failure path. Assert status and body shape only.

**Gate**: new specs pass on Rails 7.1. This *is* the before-state — written after the bump they would prove nothing.

---

## Steps 5–6 · Fix the partner-notification defect (User Story 3, P2)

### 5. Write the failing rollback spec

`spec/requests/fv1/kit_assignment_rollback_spec.rb`: given an assignment whose transaction rolls back, assert **no** `LalenApi::AssignKitTestsJob` is enqueued.

**Gate**: the spec **fails** — and fails because the job *is* enqueued, not for a setup error. Verify the failure message before proceeding.

### 6. Move the call outside the transaction

In `app/controllers/fv1/kit_controller.rb`, `assign_tests_in_lalen_api` currently sits at line 45, inside the transaction opened at line 39. Move it after the block's `end`:

```ruby
ActiveRecord::Base.transaction do
  @current_rsc.reserved_tests.destroy_all
  # ...
  @current_rsc.update!(...)
end                        # ← transaction commits here

assign_tests_in_lalen_api  # ← only reached if the commit succeeded
```

**Gate**: rollback spec passes; full suite green — still on Rails 7.1. Commit.

> Doing this here, rather than relying on the 7.2 default, is what makes the fix verifiable before the framework moves and legible at the call site afterwards.

---

## Steps 7–10 · The upgrade (User Story 4, P3)

### 7. Bump Rails and Lockbox together

These are atomic — Lockbox 2.2.0 raises unless Active Record ≥ 7.2 (see `research.md` R2).

```ruby
gem "rails", "~> 7.2.3"
# Lockbox 2.2.0 requires Active Record >= 7.2  (previous comment now obsolete — replace it)
gem "lockbox", "~> 2.2.0"
```

```bash
bundle lock --conservative --update rails lockbox
```

> **Do not run a bare `bundle update`.** It resolves, but pulls ~40 unrelated bumps including `rspec-rails` 7→8 and `sentry` 5→6, destroying failure attribution and the rollback guarantee.

**Gate**: the diff contains only the Rails stack → 7.2.3, `lockbox` → 2.2.0, and `useragent` as a new transitive dependency. Confirm `rspec-rails` is still 7.1.1 and `solid_queue` still 1.4.0.

```bash
bundle install
```

### 8. Boot and verify

```bash
for env in development test staging production; do
  RAILS_ENV=$env bin/rails runner 'puts "#{Rails.env}: #{Rails.version}"'
done
bin/rails db:migrate RAILS_ENV=test
bundle exec rspec
```

**Gate**: all four environments boot; suite green with ≥737 examples and 0 failures.

Then confirm encryption across the Lockbox major bump — patient data, so verify rather than infer:

```bash
bin/rails runner 'a = ApiAccount.where.not(settings: nil).first; puts a ? a.settings.inspect : "none"'
```

**Gate**: records written under 1.2.0 decrypt cleanly under 2.2.0.

### 9. Deprecation cleanup

- `app/models/key_value_db_store.rb:5` — `serialize :json, ::ActiveRecord::Coders::JSON` → `coder:` keyword form.
- `ActiveRecord::Base.connection` → `with_connection` at the 3 sites (one historical migration, one spec).

```bash
bundle exec rspec 2>&1 | grep -i "deprecat" | sort -u
```

**Gate**: every remaining warning is either resolved or recorded with a deferral rationale.

### 10. Verify job timing against a real worker

The test environment's in-memory `:test` adapter cannot demonstrate post-commit timing. With no staging deploy, this must be done deliberately or not at all.

```bash
bin/rails solid_queue:start    # separate terminal
```

Exercise the FFTB kit-assignment flow twice: once committing, once forcing a rollback.

**Gate**: commit path → partner notified exactly once. Rollback path → **no** enqueue, no retries.

---

## Steps 11–12 · Configuration (User Story 5, P4)

### 11. Review the generated config diff

```bash
bin/rails app:update    # review every hunk; accept nothing blindly
```

Decline the full-stack additions — this is an API-only app: browser-version guard (`allow_browser`), PWA scaffolding, DevContainers.

**Gate**: every difference has a recorded adopt-or-decline decision.

### 12. *(Optional)* `load_defaults` → 7.2

Deferrable. An app on 7.2 with 7.1 defaults is a legitimate, supported end state.

Change `config/application.rb:24` to `config.load_defaults 7.2`, then run the suite and record an adopt-or-override decision per new default.

**Gate**: suite green; no unrecorded default; no unintended API-visible change.

---

## Rollback

Any step reverts independently. Full revert:

```bash
git checkout main -- Gemfile Gemfile.lock
bundle install
bundle exec rspec              # must reproduce the baseline exactly
```

**Gate**: the baseline example/failure counts return exactly (SC-014).

---

## Completion checklist

- [ ] Baseline recorded and reproducible
- [ ] All 12 audit entries re-verified
- [ ] `csv` / `base64` declared; lockfile diff minimal
- [ ] `regspec` smoke checks written **before** the bump
- [ ] Rollback spec written failing, then passing
- [ ] Partner notification fires only after commit
- [ ] Rails 7.2.3 + Lockbox 2.2.0; no unrelated gem movement
- [ ] Four environments boot; suite green; encryption verified
- [ ] Deprecations resolved or recorded
- [ ] Both job paths observed against a real worker
- [ ] Config diff reviewed; full-stack features declined
- [ ] Ruby still 3.3.7 in all three pin locations
- [ ] No LabSample schema change
- [ ] Written record: what changed, what was verified, what was deferred, how to revert
