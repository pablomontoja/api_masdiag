# Quickstart: Executing the Rails 8.0 Upgrade

**Feature**: 009-rails-80-upgrade | **Date**: 2026-08-18

Sixteen steps in six phases, each with a gate. **If a gate fails, stop and revert that step.**

Phases 0–1 run on Rails 7.2.3 and are worth shipping even if the framework bump is abandoned.

> Every command runs under `rvm use 3.4.10`. Ruby does not change in this upgrade.

---

## Phase 0 · Baseline (Rails 7.2.3)

### 1. Record the baseline

```bash
rvm use 3.4.10
ruby -v                                   # expect: ruby 3.4.10
bundle exec rspec 2>&1 | tail -3          # record examples / failures / runtime
cp Gemfile.lock /tmp/baseline-009-Gemfile.lock
cp db/schema.rb /tmp/baseline-009-schema.rb
bin/rails routes > /tmp/baseline-009-routes.txt    # the "before" side for step 11's reachability check
git rev-parse HEAD
grep -n "define_version" db/schema.rb | head -1
```

Record: example count, failure count, runtime, Ruby 3.4.10, Rails 7.2.3, schema version, route
count, commit SHA.

**Gate**: suite green. **If not, stop** — every later comparison depends on this.

### 1b. Persist the encryption probe — **now, on Rails 7.2.3**

This cannot be done later. A value written after the upgrade proves only same-version behaviour;
cross-version compatibility requires ciphertext produced by the *old* runtime.

```bash
bin/rails runner '
  a = ApiAccount.create!(username: "enc_probe_009", password: "x",
                         contractor_id: Contractor.first&.Id)
  a.settings = { probe: "pre-rails-80" }
  a.save!
  puts "probe id: #{a.id}"
'
```

**Gate**: the record exists and its id is recorded in `baseline.md`. Step 12 reads this exact record.

### 2. Prove the blocker set (FR-001)

Do not trust the scan. Make resolution say it:

```bash
cp Gemfile /tmp/Gemfile.probe-009
sed -i 's|gem "rails", "~> 7.2.3"|gem "rails", "~> 8.0.5"|' Gemfile
bundle lock 2>&1 | tail -30      # EXPECT FAILURE naming the blockers
git checkout Gemfile             # restore immediately
```

**Gate**: the failure names `rails-i18n` and `annotate` — and **nothing else**. A third gem here is a
new blocker at equal priority (FR-001); record it and resolve it before continuing.

---

## Phase 1 · Clear the blockers (still Rails 7.2.3)

### 3. Bump `rails-i18n`

```ruby
# Gemfile
gem "rails-i18n", "~> 8.0"     # was unpinned, resolving to 7.0.10
```

```bash
bundle lock --conservative --update rails-i18n
git diff Gemfile.lock
```

**Gate**: only `rails-i18n` moves. Rails must stay 7.2.3.

### 4. Verify both locales still resolve (FR-002, SC-012)

A missing key does **not** raise — it degrades to the humanised key name inside an API error body.

```bash
bin/rails runner '
  %i[pl en].each do |loc|
    I18n.locale = loc
    %w[
      errors.messages.blank errors.messages.taken
      errors.messages.invalid errors.messages.required
      number.format.separator date.formats.default
    ].each do |k|
      v = I18n.t(k, default: "__MISSING__")
      puts "#{loc} #{k} => #{v}"
    end
  end
'
```

**Gate**: zero `__MISSING__`, and Polish strings are actually Polish. Then `bundle exec rspec` must
reproduce the baseline.

### 5. Swap `annotate` → `annotaterb` (FR-003)

```ruby
# Gemfile, in the :development, :test group
gem "annotaterb"     # replaces `gem 'annotate'` — 3.2.0 is its final release and caps AR < 8.0
```

```bash
bundle lock
git diff Gemfile.lock | grep -E "^[-+]\s+(annotate|annotaterb)"
```

**Gate**: `annotate` removed, `annotaterb` added, nothing else moved.

### 6. Compare annotation output — **do not commit a regeneration yet**

There is no config file; the old gem ran on defaults, and 39 of 58 models are annotated. A blind
regeneration would annotate all 58 and bury the upgrade in a 19-file unrelated diff.

```bash
git stash list                     # ensure clean tree first
bundle exec rake annotate_models   # or: bundle exec annotaterb models
git diff --stat
git diff app/models/api_account.rb | head -40
```

**Gate**: decide from the diff.
- Blocks semantically equivalent, few files touched → commit if you want.
- Wholesale reformat, or 19 newly annotated models → **`git checkout app/models/` and defer.**

Deferring is a fine outcome. The swap is what unblocks resolution; regeneration is optional
(research.md R3).

### 7. Reproduce the baseline and commit Phase 1

```bash
bundle exec rspec 2>&1 | tail -3
```

**Gate**: matches step 1 exactly. Commit — this ships independently of the framework bump.

---

## Phase 2 · The framework bump

### 8. Confirm the target patch (FR-005)

```bash
gem list -r -e rails --all | tr ',' '\n' | grep -E "^\s*8\.0\." | head -3
```

Planning assumed **8.0.5.1**. If a newer 8.0.x has published, take it and record why it differs.
Spec 008 hit exactly this (3.4.9 → 3.4.10). Do **not** take 8.1 — out of scope.

### 9. Bump Rails

```ruby
# Gemfile
gem "rails", "~> 8.0.5"
```

```bash
bundle lock --conservative --update rails
git diff Gemfile.lock | grep -E "^[-+]    [a-z]"
```

**Gate (FR-004)**: only the framework gems and gems Rails itself forces may move. Any unrelated gem
movement — `rspec-rails`, `sentry`, `alba`, `oj` — stops the step. Then:

```bash
bundle install
bin/rails runner 'puts Rails.version'     # expect 8.0.5.1
```

### 10. Run `app:update` and review **every** hunk (FR-006)

```bash
bin/rails app:update
git status
git diff
```

**Gate**: each proposed change applied with a reason or rejected with a reason. **Bulk acceptance is
forbidden.** Watch for overwrites of `config/environments/*.rb` and `config/application.rb` — the app
has deliberate settings there (`solid_queue.use_skip_locked`, `mission_control.jobs.*`,
`default_column_serializer`, i18n locales) that must survive.

`config/initializers/new_framework_defaults_8_0.rb` is created here. **Leave every line commented
out** — defaults are adopted in Phase 4, not now.

### 11. Verify the bump

```bash
bin/rails runner 'puts "boot ok: #{Rails.version} / defaults #{Rails.application.config.load_defaults_version rescue "7.2"}"'
bundle exec rspec
git diff db/schema.rb                     # MUST be empty (FR-020)
```

**Gate**: app boots, suite green, no example-count reduction, `db/schema.rb` untouched.

Then all 11 namespaces per `contracts/namespace-equivalence.md`:

```bash
bundle exec rspec spec/requests/v1_*.rb
bundle exec rspec spec/requests/fv1_*.rb spec/requests/fv1/
bundle exec rspec spec/requests/nume_*.rb
bundle exec rspec spec/requests/toxo/
bundle exec rspec spec/requests/regspec/
bundle exec rspec spec/requests/masdiag/
bundle exec rspec spec/requests/lalen*
bundle exec rspec spec/requests/masdiag_mailer/
bundle exec rspec spec/requests/api/webhook/
bundle exec rspec spec/requests/dp_shop_orders_spec.rb
```

**Gate (FR-009)**: all pass with **zero assertions modified**. `git diff spec/` must be empty. If a
spec needs changing to pass, that is a **contract change** — escalate and explain before touching it.

Then confirm no endpoint became newly reachable (FR-010, SC-006):

```bash
bin/rails routes > /tmp/after-009-routes.txt
diff /tmp/baseline-009-routes.txt /tmp/after-009-routes.txt
```

**Gate**: no added routes. A route that exists after the upgrade but not before is a reachability
regression, regardless of whether any spec covers it.

---

## Phase 3 · Behavioural verification

### 12. Encryption round-trip (FR-015)

Read the probe written in **step 1b** — do not create one here. A record written now would be
encrypted by the new runtime and would prove nothing about cross-version compatibility.

```bash
bin/rails runner '
  a = ApiAccount.find_by(username: "enc_probe_009")
  abort "probe missing — step 1b was skipped; FR-015 cannot be verified" if a.nil?
  puts "decrypted on Rails #{Rails.version}: #{a.settings.inspect}"
  puts "expected: {:probe=>\"pre-rails-80\"}"
  puts "opaque: #{!a.settings_ciphertext.to_s.include?("pre-rails")}"
'
```

**Gate**: the value written on Rails 7.2.3 decrypts correctly on 8.0.5.x; ciphertext contains no
plaintext. If the probe is missing, FR-015 is unverifiable without redoing the upgrade — record it
as a gap rather than substituting a fresh record.

### 13. Partner notification, against a real worker (FR-013)

The test adapter cannot prove this — spec 007 established that `use_transactional_fixtures` turns
the controller transaction into a savepoint.

```bash
bin/rails solid_queue:start        # separate terminal
```

Exercise the FFTB kit-assignment flow twice: once committing, once forcing a rollback.

**Gate**: commit → **exactly 1** partner notification. Rollback → **0**.

### 14. The `/jobs` dashboard (FR-008a, FR-008b)

The least obvious risk: only asset-serving surface, zero asset config, and Rails 8 changes the
default pipeline.

```bash
bin/rails s
```

Open `http://localhost:3000/jobs` **in a browser** and check the network tab.

**Gate**:
- Page **renders** — styling applied, scripts loaded, zero failed asset requests. HTTP 200 alone is
  not sufficient; a broken stylesheet still returns 200.
- Invalid credentials refused; unauthenticated access refused.

### 15. Container build (FR-008)

The container toolchain differs from the workstation's and is what production runs.

```bash
docker compose build
docker compose run --rm app bin/rails runner 'puts Rails.version'
```

**Gate**: image builds; app boots inside it.

> If this fails with `Expected name: to be a String, got NilClass` at `admin_controller.rb`, it is
> the known credentials-at-runtime gap, not an upgrade regression: `RAILS_MASTER_KEY` is supplied
> under `build.args` but not under `environment` in `docker-compose.yml`.

---

## Phase 4 · Adopt the 8.0 defaults

Only after Phases 2–3 are green. This separation is what makes a defaults-induced failure
distinguishable from a bump-induced one.

### 16. Adopt, and make the notification guarantee explicit

```ruby
# config/application.rb
config.load_defaults 8.0

# Explicit, not inherited. The constitution (Development Workflow item 4) requires that
# ordering-critical enqueue intent "survive a defaults change" — this is that change.
config.active_job.enqueue_after_transaction_commit = :default
```

Review `config/initializers/new_framework_defaults_8_0.rb` line by line, recording each decision
(FR-019).

```bash
bundle exec rspec
bin/rails runner 'puts ActiveJob::Base.enqueue_after_transaction_commit.inspect'
```

**Gate**: suite green; the enqueue setting reads from explicit config (FR-014, SC-009).

Then **re-run all 11 namespaces** (SC-013a) and **repeat step 13** — the commit/rollback exercise is
what proves the guarantee survived the defaults change.

### Regex sites under the new timeout (FR-017, SC-011)

```bash
bin/rails runner '
  long = "a"*300 + "@" + "b"*300 + ".com"
  [ "valid@example.com", "not-an-email", long, "", "a@b.co" ].each do |s|
    begin
      m = LalenApi::RegisterKit::EMAIL_REGEXP.match?(s)
      puts "#{s[0,25].inspect} => #{m}"
    rescue Regexp::TimeoutError => e
      puts "TIMEOUT: #{s[0,25].inspect}"
    end
  end
'
```

**Gate**: same verdicts as before, **zero** timeouts. Any timeout is a blocking finding.

---

## Phase 5 · Record

### Equivalence report (FR-009a)

Per namespace: specs exercised, pass/fail, coverage assessment, and whether coverage substantiates
the claim. **Name the thin ones**: `lalen` (2 files, partner-facing), `masdiag_mailer` (1),
`webhook` (1), `diagnostyka_precyzyjna` (1), `patient_portal` (0, structural only).

### Warning review (FR-023)

```bash
bundle exec rspec 2>&1 | grep -iE "warning|deprecat" | sort -u
```

**Gate**: each resolved or recorded with a rationale.

### Upgrade record (FR-024)

Versions before/after, every dependency that moved and why, every default adopted and why, every
deferral with its reason, and the revert procedure.

**Gate**: another developer can act on it without reading the diff.

---

## Rollback

```bash
git checkout main -- Gemfile Gemfile.lock config/application.rb
rm -f config/initializers/new_framework_defaults_8_0.rb
bundle install
bundle exec rspec              # must reproduce the step-1 baseline exactly
```

**Gate**: baseline returns exactly (SC-016).

> **Revert the framework and the dependent code together.** Spec 007 reverted only the lockfile,
> left newer code in place, and produced 13 failures that masked the real state (FR-025).

---

## Completion checklist

- [ ] Baseline recorded and reproducible (suite, lockfile, schema, **routes**, commit)
- [ ] Encryption probe persisted on Rails 7.2.3 **before** any change (step 1b)
- [ ] Blocker set proven by resolution — exactly two, or extras recorded
- [ ] `rails-i18n` on 8.0.x; both locales resolve, zero fallbacks
- [ ] `annotaterb` swapped in; regeneration committed **or** deliberately deferred
- [ ] Phase 1 committed independently (ships without the bump)
- [ ] Target patch confirmed at implementation time and recorded
- [ ] Rails on 8.0.5.x; no unrelated gem moved
- [ ] `app:update` reviewed hunk by hunk; deliberate config settings preserved
- [ ] Suite green; example count not reduced; `db/schema.rb` untouched
- [ ] All 11 namespaces pass with **zero assertions modified** (`git diff spec/` empty)
- [ ] Route diff against the baseline shows no newly reachable endpoint
- [ ] The step-1b probe decrypts correctly on the new framework version
- [ ] Commit → 1 notification, rollback → 0, against a real worker
- [ ] `/jobs` dashboard **renders**; auth still refuses invalid credentials
- [ ] Container image builds and boots
- [ ] `load_defaults 8.0` adopted; enqueue-after-commit set **explicitly**
- [ ] Suite + 11 namespaces verified a **second** time; commit/rollback repeated
- [ ] All 6 regex sites verified; zero timeouts
- [ ] Ruby still 3.4.10; schema unchanged
- [ ] Equivalence report names the thin-coverage namespaces
- [ ] Warnings resolved or recorded
- [ ] Upgrade record complete
