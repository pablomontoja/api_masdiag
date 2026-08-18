# Quickstart: Executing the Ruby 3.4 Upgrade

**Feature**: 008-ruby-34-upgrade | **Date**: 2026-08-17

Thirteen steps, each with a gate. **If a gate fails, stop and revert that step.** Steps 1–4 run on
Ruby 3.3.7 and are valuable even if the runtime change is abandoned.

---

## Steps 1–4 · Preparation on Ruby 3.3.7

### 1. Record the baseline

```bash
rvm use 3.3.7
bundle exec rspec 2>&1 | tail -3          # expect: 755 examples, 0 failures
cp Gemfile.lock /tmp/baseline-008-Gemfile.lock
git rev-parse HEAD
```

Record: example count, failure count, runtime, Ruby version, Rails version (must stay 7.2.3).

**Gate**: suite green. **If not, stop** — every later comparison depends on this.

### 2. Re-scan for undeclared stdlib requires

The trial found only `observer`, but FR-002 requires confirming that rather than trusting it.

```bash
for g in observer ostruct bigdecimal drb logger benchmark mutex_m abbrev syslog getoptlong; do
  n=$(grep -rE "require .$g." app/ lib/ config/ spec/ 2>/dev/null | wc -l)
  d=$(grep -cE "^gem .$g." Gemfile)
  printf "%-11s require:%s declared:%s\n" "$g" "$n" "$d"
done
```

Also check gems that require them internally:

```bash
grep -rln "require 'observer'\|require \"observer\"" \
  $(bundle show --paths 2>/dev/null | head -50) 2>/dev/null | head
```

**Gate**: every component is declared or confirmed unused. Anything new goes into the E2 record.

### 3. Write the encryption round-trip check — **before** the runtime changes

Create `spec/models/encryption_round_trip_spec.rb` asserting that an encrypted `ApiAccount#settings`
value round-trips and that ciphertext never contains plaintext.

Then persist a record whose ciphertext can be read back **after** the runtime change:

```bash
bin/rails runner '
  a = ApiAccount.create!(username: "enc_probe_008", password: "x",
                         contractor_id: Contractor.first&.Id)
  a.settings = { probe: "pre-ruby-34" }; a.save!
  puts "probe id: #{a.id}"
'
```

**Gate**: spec passes on 3.3.7 and the probe record exists. Written after the change it would only
prove same-runtime behaviour, not cross-runtime compatibility.

### 4. Declare `observer`

```ruby
# Gemfile, beside the existing csv/base64 declarations
gem "observer"  # required by factory_bot 4.11; not a Ruby default gem from 3.4
```

```bash
bundle lock        # plain resolution — --conservative --update CANNOT add a new gem
git diff Gemfile.lock
```

**Gate**: the diff adds **only** `observer`. Rails must remain 7.2.3 and no other gem may move.
Then `bundle exec rspec` must reproduce the baseline. Commit — this ships independently.

---

## Steps 5–7 · The runtime change

### 5. Install Ruby 3.4.10

RVM's known-list is stale on this machine (`rvm list known | grep 3.4` returns nothing), so refresh
first or the install will fail:

```bash
rvm get stable
rvm install 3.4.10
rvm use 3.4.10
ruby -v                      # expect: ruby 3.4.10
```

**Gate**: `ruby -v` reports 3.4.10.

> Targeting 3.4.10, not the sandbox trial's 3.4.9 — a newer patch has published since. See
> `research.md` R1.

### 6. Update the three version pins

```bash
echo "ruby-3.4.10" > .ruby-version
# Gemfile:    ruby "3.3.7"            → ruby "3.4.10"
# Dockerfile: ARG RUBY_VERSION=3.3.7  → ARG RUBY_VERSION=3.4.10
```

**Gate**: all three agree.

```bash
cat .ruby-version; grep '^ruby ' Gemfile; grep 'ARG RUBY_VERSION' Dockerfile
```

### 7. Install dependencies on the new runtime

```bash
bundle install
```

> **Do not run `bundle update`.** The lockfile must be regenerated for the new `RUBY VERSION`
> stanza, not re-resolved. The sandbox trial used an unconstrained update and pulled in ~20 unrelated
> gems (`alba`, `oj`, `rack`, `aws-sdk-s3`, …).

**Gate**: all source-compiled gems build (`mysql2`, `bcrypt`, `oj`, `bootsnap`, `msgpack`, `puma`,
`json`, `racc`, `date`, `prawn`, `caxlsx`). Then:

```bash
git diff Gemfile.lock | grep -E "^[-+]    [a-z]" | grep -v observer
```

**Gate**: this must show **only** the `RUBY VERSION` stanza change and platform-variant lines for
`ffi`/`nokogiri`. Any other gem version movement — stop and investigate.

---

## Steps 8–12 · Verification

### 8. Suite and namespace equivalence

```bash
bin/rails db:migrate RAILS_ENV=test
git diff db/schema.rb              # must be EMPTY — a Ruby change must not touch schema
bundle exec rspec
```

**Gate**: ≥755 examples, 0 failures; `db/schema.rb` unchanged.

Then per namespace (see `contracts/runtime-compatibility.md`):

```bash
bundle exec rspec spec/requests/api spec/requests/regspec \
  $(ls spec/requests/fv1_*.rb) $(ls spec/requests/nume_*.rb) \
  spec/requests/masdiag spec/requests/masdiag_mailer spec/requests/lalen spec/requests/fv1
```

**Gate**: all 8 in-scope namespaces pass.

### 9. Encryption and real-worker job behaviour

```bash
bin/rails runner '
  a = ApiAccount.find_by(username: "enc_probe_008")
  puts "decrypted on #{RUBY_VERSION}: #{a.settings.inspect}"
  puts "ciphertext opaque: #{!a.settings_ciphertext.to_s.include?("pre-ruby-34")}"
'
```

**Gate**: the value written on 3.3.7 decrypts correctly on 3.4.10.

Then, with a real worker (`solid_queue_db` now exists locally):

```bash
bin/rails solid_queue:start     # separate terminal
```

Exercise the FFTB kit-assignment flow twice — once committing, once forcing a rollback.

**Gate**: commit → exactly one partner notification. Rollback → none.

### 10. Container build

```bash
docker build --build-arg RUBY_VERSION=3.4.10 -t api_masdiag:ruby34 .
```

**Gate**: image builds — all source-compiled gems build inside `ruby:3.4.10-slim`, whose toolchain
differs from the workstation's. This is the check the sandbox trial could not perform.

### 11. Warning review

```bash
bundle exec rspec 2>&1 | grep -iE "warning|deprecat" | sort -u
```

**Gate**: each warning resolved or recorded with a rationale. The trial showed zero after declaring
`observer`.

### 12. Write the upgrade record

Record what changed, what was verified, what was deferred, and how to revert (FR-020, SC-014).

**Gate**: another developer can act on it without reading the diff.

---

## Step 13 · *(Optional)* `factory_bot` assessment

Compare 4.11.1 against the current 6.x line, record the breaking changes, and decide upgrade-now or
defer-with-reason. If deferring, ensure the `observer` declaration explains what would retire it.

**Gate**: a recorded decision either way.

---

## Rollback

```bash
rvm use 3.3.7
git checkout main -- Gemfile Gemfile.lock .ruby-version Dockerfile
bundle install
bundle exec rspec              # must reproduce 755 examples, 0 failures
```

**Gate**: the baseline returns exactly (SC-012).

> Lesson from spec 007: revert the **runtime and the files together**. Reverting only the lockfile
> while leaving newer code in place produced 13 failures there.

---

## Completion checklist

- [ ] Baseline recorded and reproducible
- [ ] Stdlib scan complete; every component declared or confirmed unused
- [ ] Encryption probe written and persisted **before** the change
- [ ] `observer` declared; lockfile diff minimal
- [ ] Ruby 3.4.10 installed; all three pins agree
- [ ] `bundle install` moved no unrelated gem
- [ ] Suite ≥755 examples, 0 failures; `db/schema.rb` untouched
- [ ] All 8 in-scope namespaces pass
- [ ] Pre-change encrypted data decrypts on the new runtime
- [ ] Job commit/rollback paths observed against a real worker
- [ ] Container image builds and the application starts
- [ ] Warnings resolved or recorded
- [ ] Rails still 7.2.3 — the framework must not have moved
- [ ] Written record complete
