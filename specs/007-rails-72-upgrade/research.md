# Phase 0 Research: Rails 7.2 Upgrade

**Feature**: 007-rails-72-upgrade | **Date**: 2026-08-17

All findings below were produced by executing the resolution locally, not by reading documentation. Trial lockfiles live in the session scratchpad and are disposable; what matters is the recorded outcome.

---

## R1 — Target Rails version

**Decision**: Rails **7.2.3** (`gem "rails", "~> 7.2.3"`).

**Rationale**: Latest 7.2 series release available at time of planning, verified against the RubyGems index. The application is already on 7.1.6, which is the latest 7.1 patch — so the "move to the latest patch of the current minor first" step is already satisfied and requires no separate action.

**Alternatives considered**:
- *7.2.0* — no reason to adopt the oldest 7.2 release; forgoes patch fixes.
- *Rails 8.x* — available (8.1.3.1) but out of scope; the guidance is one minor at a time, and 7.2 is the prerequisite regardless.

---

## R2 — The `lockbox` pin (highest-risk unknown → resolved, and it inverts)

**Decision**: Move `lockbox` from `~> 1.2.0` to `~> 2.2.0` **as part of the Rails bump, not optionally**.

**Finding**: The `Gemfile` comment reads *"Lockbox >= 2.2 refuses to load on Active Record 7.1"*. Inspecting the gem source (`lockbox-2.2.0/lib/lockbox.rb:98-113`) shows the actual gate:

```ruby
ActiveSupport.on_load(:active_record) do
  ar_version = ActiveRecord::VERSION::STRING.to_f
  if ar_version < 7.2
    if ar_version >= 7.1
      raise Lockbox::Error, "Active Record #{...} requires Lockbox < 2.2"
    ...
```

The condition is `ar_version < 7.2`. Lockbox 2.2.0 requires Active Record **≥ 7.2 exactly**. The constraint is therefore not merely liftable on 7.2 — it **reverses**: 2.2.0 is unusable today and becomes the correct version the moment Rails reaches 7.2.

**Consequence**: the version bump and the lockbox bump are a single atomic change. Bumping Rails while leaving lockbox at 1.2.0 is untested territory; bumping lockbox first is impossible. The `Gemfile` comment must be updated or removed, since it will be actively misleading afterwards.

**Risk note**: Lockbox encrypts patient data (`ApiAccount#settings`, `OnlineFile` content). A major version move on an encryption library warrants explicit decrypt-existing-records verification, even though the gem is API-stable across this boundary.

**Alternatives considered**:
- *Keep lockbox 1.2.0 on Rails 7.2* — the gem's own guard does not forbid this direction, but it is an unsupported combination the maintainer clearly does not intend. Rejected.

---

## R3 — Full dependency graph compatibility

**Decision**: No blocking dependency. The upgrade is viable.

**Method**: Constructed a trial `Gemfile` with Rails 7.2.3, lockbox 2.2.0, plus `csv`/`base64`, and ran a full `bundle lock` resolution on Ruby 3.3.7.

**Result**: **Resolved cleanly**, including the git-sourced `k-php-serialize` gem that automated compatibility services cannot assess. This retires FR-002/FR-003/FR-006 as risks — the assessment story can now confirm rather than discover.

**Alternatives considered**:
- *RailsBump / per-gem `gem dependency` queries* — attempted first; slow, rate-limited, and unreliable (several gems report "no rails dep" because they constrain `railties` transitively or not at all). Actually resolving the graph is both faster and authoritative. Rejected as the primary method, though still useful for narrating *why* a specific gem moves.

---

## R4 — Update strategy: conservative, not wholesale ⚠️

**Decision**: Use a **targeted conservative update** (`bundle lock --conservative --update rails lockbox`), never a bare `bundle update`.

**Finding**: This is the single most important operational finding of Phase 0. An unconstrained `bundle lock --update` resolves successfully but drags in a large set of unrelated upgrades:

| Gem | Current | Unconstrained update | Nature |
|-----|---------|----------------------|--------|
| `rspec-rails` | 7.1.1 | **8.0.4** | major |
| `sentry-ruby` / `sentry-rails` | 5.x | **6.7.0** | major |
| `solid_queue` | 1.4.0 | 1.6.0 | minor, job backend |
| `rack` | 3.1.x | 3.2.7 | minor |
| `alba`, `oj`, `aws-sdk-s3`, `bootsnap`, … | — | newer | assorted |

Roughly 40 gems move. Any resulting failure would be unattributable — precisely the outcome the spec's "one variable at a time" principle exists to prevent, and it would compromise the rollback guarantee (FR-023).

**Verified alternative**: the conservative targeted update produces a minimal, attributable diff:

```
actioncable, actionmailbox, actionmailer, actionpack, actiontext, actionview,
activejob, activemodel, activerecord, activestorage, activesupport,
rails, railties          → 7.2.3
lockbox                  → 2.2.0
useragent (0.16.11)      → new transitive dependency of the Rails stack
```

`rspec-rails` stays 7.1.1, `solid_queue` stays 1.4.0, sentry stays on 5.x. Exactly the framework and its forced companion, nothing else.

---

## R5 — Sequencing constraint on adding `csv` / `base64`

**Decision**: Add `csv` and `base64` as a **separate, earlier commit on Rails 7.1**, before the framework bump.

**Finding**: `bundle lock --conservative --update <gems>` **cannot introduce gems that are not already in the lockfile** — it fails with `Could not find gem 'csv'`. Adding a new dependency requires a plain resolution pass. Attempting to combine both changes therefore forces either an unconstrained update (rejected per R4) or an awkward two-mode invocation.

**Verified outcome of doing it standalone on Rails 7.1**: the lockfile gains **exactly one line** — `csv (3.3.6)`. `base64 (0.3.0)` is already present transitively and simply becomes explicit. Rails remains 7.1.6. Nothing else moves.

This is the cleanest possible confirmation that User Story 2 is independently shippable with essentially zero blast radius, exactly as the spec claims.

**Alternatives considered**:
- *Bundle it into the Rails commit* — muddies an otherwise minimal diff and forfeits the ability to ship the latent-defect fix on its own. Rejected.

---

## R6 — Adopting post-commit job enqueuing (clarified decision)

**Decision**: Restructure the affected call site so correctness does not depend on the framework's enqueuing semantics, **and** rely on the 7.2 default rather than configuring an opt-out.

**Finding**: `app/controllers/fv1/kit_controller.rb:39-46` calls `assign_tests_in_lalen_api` at line 45, inside the transaction. That method enqueues `LalenApi::AssignKitTestsJob`, which POSTs the kit barcode to an external partner (Lalen/FFTB, institution 83) and retries up to 10 times.

Two mechanisms could produce the required behaviour:

1. **Move the call after the transaction block** (`end` at line 46), so the enqueue provably happens post-commit under *any* framework version.
2. **Rely on `enqueue_after_transaction_commit`**, the 7.2 default, leaving the code as-is.

**Chosen: (1), with (2) as reinforcement.** Rationale: option 1 is verifiable on Rails 7.1 *today*, satisfying FR-015 and the User Story 3 independence claim, and it makes the intent legible at the call site instead of depending on a distant framework default. Option 2 alone would make the fix invisible in the code and unverifiable until after the version bump.

This also aligns with Constitution Principle II — a controller action orchestrating a transaction plus an external notification is business logic, and the notification's ordering relative to the commit is exactly the kind of thing that should be explicit.

**Alternatives considered**:
- *`after_commit` callback on the model* — would work, but the constitution explicitly prohibits "Callback Hell / hidden side effects" and the enqueue is currently controller-driven, not model-driven. Rejected.
- *Global `config.active_job.enqueue_after_transaction_commit = :never`* — rejected by clarification; preserves the defect.

---

## R7 — Ruby version

**Decision**: Ruby stays at **3.3.7**. No change in this feature.

**Rationale**: Decided during clarification. 3.3.7 already exceeds the 3.1 minimum Rails 7.2 requires. Verified that `.ruby-version`, `Gemfile`, and `Dockerfile` (`ARG RUBY_VERSION=3.3.7`) currently agree; the plan must preserve that invariant rather than change it.

**Verified for the future feature**: on Ruby 3.4.9, `require "csv"` fails with *"csv is not part of the default gems starting from Ruby 3.4.0."* Handling this in the present feature (R5) removes the blocker in advance.

---

## R8 — Verification approach

**Decision**: Local verification against a running Solid Queue worker; no staging deployment.

**Rationale**: Clarified decision. The consequence for the plan is that the commit and rollback paths of the partner notification must be exercised **deliberately** — with no deployment soak, nothing will surface them incidentally. The test environment uses the in-memory `:test` adapter, which by construction cannot demonstrate the post-commit timing that R6 adopts.

**Practical requirement**: a `regspec` smoke-check suite must be written before the bump (it has zero request specs today), so it can produce a genuine before/after comparison. Written after the bump, it would only ever document post-upgrade behaviour and prove nothing.

---

## Residual unknowns

None blocking. Two items deliberately deferred to execution:

1. **Exact 7.2 framework-defaults list** — belongs to User Story 5 (P4) and should be read from the generated configuration diff at execution time rather than transcribed here, since it varies by patch release.
2. **Whether historical partner notifications need reconciling** — recorded in the spec as a business data question outside this upgrade.
