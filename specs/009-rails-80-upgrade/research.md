# Phase 0 Research: Rails 7.2 → 8.0 Upgrade

**Feature**: 009-rails-80-upgrade | **Date**: 2026-08-18

All findings below were verified against the repository and the RubyGems index on 2026-08-18, not
inferred from the upgrade guide. Where the guide and the codebase disagree, the codebase wins.

---

## R1 — Target framework version

**Decision**: Pin to **Rails 8.0.5.1**, verifying at implementation time that no newer 8.0.x has
published in the interim.

**Rationale**: The clarification session settled on "latest 8.0.x at implementation time, pinned
exactly". As of today the 8.0 line runs to 8.0.5.1. The `.1` suffix marks it a security release —
8.0.5 and 8.0.5.1 are otherwise the same feature set — which makes deliberately installing anything
earlier hard to justify on an application handling patient data.

`required_ruby_version` for 8.0.5.1 is `>= 3.2.0`. The application runs Ruby 3.4.10, so this
prerequisite is already satisfied; spec 008 paid that cost in advance. This is the one place the
source guide's recommended ordering ("Ruby 3.2+ first, separately") has already been honoured.

**Alternatives considered**:
- *8.0.0* — matches the guide's reference point but ships without five patch releases of fixes,
  including security ones. Rejected.
- *`~> 8.0.0` without a patch pin* — lets the resolved version drift between the workstation, the
  container, and staging. The whole point of recording the version is that all three agree.
- *Rails 8.1* — **exists** (8.1.3.1 is current). Explicitly out of scope: this spec targets 8.0, and
  jumping two minors at once would conflate two sets of breaking changes. Worth a future spec 010;
  recorded here so the option is not lost.

---

## R2 — Blocker 1: `rails-i18n`

**Decision**: Raise `rails-i18n` from 7.0.10 to the **8.0.x** line (8.0.2 current).

**Rationale**: 7.0.10 declares `railties (>= 6.0.0, < 8)` — a hard resolution failure against Rails
8. The 8.0 line exists and is the direct successor; its only runtime dependency is `i18n (>= 0.7,
< 2)`, which the application already satisfies. The gem ships locale data, not behaviour, so the
risk is confined to translation content rather than code paths.

**What must be verified rather than assumed**: this gem supplies the *framework's* default
translations (validation error messages, date and number formats) for `:pl` and `:en`. A changed or
removed key does not raise — it silently falls back to the humanised key name, which would surface
as a corrupted error message in an API response rather than as a failure. FR-002 and SC-012 exist
because of this failure mode. Validation error bodies are part of the contract that FR-011 protects.

**Alternatives considered**:
- *Remove the gem and hand-maintain locales* — the application sets
  `config.i18n.available_locales = [:pl, :en]` and relies on Polish framework messages. Replacing
  that by hand is strictly more work and more risk than a version bump.

---

## R3 — Blocker 2: `annotate` → `annotaterb`

**Decision**: Replace `annotate` (3.2.0, final release, caps `activerecord < 8.0`) with
**`annotaterb`** (4.24.0 current), per the clarification session.

**Rationale**: `annotaterb` is the maintained fork of exactly this gem and continues the same
workflow — schema comment blocks written into model files. It is in the `:development, :test` group,
so it cannot affect runtime behaviour of the API. That is what makes this swap low-risk and what
keeps outright removal available as a fallback (FR-003's recorded escape hatch).

**Findings that change how this is executed** — three facts about the current state that the spec
could not have known:

1. **There is no annotate configuration file.** No `.annotaterb.yml`, no
   `lib/tasks/auto_annotate_models.rake`, nothing in `Rakefile`. The gem has been running on pure
   defaults. This makes the migration *simpler* than feared — there is no configuration to carry
   across — but it also means the new gem's defaults are the only thing determining output, and its
   defaults are not identical to the old gem's.

2. **39 of 58 models carry annotation blocks; 19 do not.** The annotations are not uniformly
   applied. A blind regeneration would annotate all 58, producing a 19-file diff that has nothing to
   do with this upgrade. FR-003 requires the regenerated blocks be *semantically equivalent* — that
   requirement is aimed precisely at this.

3. **Annotations sit at the top of the file** (`# == Schema Information` as line 1), in the classic
   format with aligned column names, types and modifiers. `annotaterb` defaults to the same position
   and a compatible format, but alignment and the exact rendering of type modifiers are the details
   most likely to drift.

**Consequence for the plan**: the safest sequence is to install the fork, generate annotations into
a *scratch* state, diff against the current blocks, and only then decide whether to commit a
regeneration at all. Since the gem is dev-tooling, **the upgrade does not require regenerating
annotations**. Swapping the dependency unblocks resolution; regenerating is optional and can be
deferred or skipped entirely. Treating the swap and the regeneration as one step is what would
create a large, noisy, upgrade-obscuring diff.

**Alternatives considered**:
- *Remove annotations entirely* — viable fallback (FR-003), but discards a working developer aid for
  no gain when a maintained fork exists.
- *Vendor/fork `annotate` and relax its constraint* — takes on maintenance of a dead gem to avoid
  changing one Gemfile line. Rejected.

---

## R4 — Are there other blockers?

**Decision**: Treat `rails-i18n` and `annotate` as the complete known set, and treat actual
dependency resolution as the authority that confirms it (FR-001).

**Rationale**: A scan of every declared upper bound in `Gemfile.lock` found exactly two gems
excluding Rails 8. All other Rails-dependent gems declare open lower bounds:

| Gem | Declared bound | Verdict |
|---|---|---|
| `rails-i18n` 7.0.10 | `railties (>= 6.0.0, < 8)` | **Blocker** — bump to 8.0.x |
| `annotate` 3.2.0 | `activerecord (>= 3.2, < 8.0)` | **Blocker** — replace with fork |
| `solid_queue` 1.4.0 | `activejob/activerecord/railties (>= 7.1)` | Clear |
| `mission_control-jobs` 1.1.0 | `actionpack/activerecord/… (>= 7.1)` | Clear, and already latest |
| `sentry-rails`, `mobility`, `money-rails`, `pundit`, `groupdate`, others | open lower bounds | Clear |

**The limitation of this method, stated plainly**: scanning declared bounds finds gems that *say*
they are incompatible. It cannot find gems that merely *are* — a gem with an open bound can still
break against Rails 8. Resolution catches the first class of problem; only the test suite catches
the second. This is why FR-001 mandates proving the set by resolution and why the spec carries an
edge case for a third blocker emerging late.

---

## R5 — The job dashboard and the asset pipeline

**Decision**: Keep the dashboard on its current gems, verify it renders (FR-008a), and adopt no
asset-pipeline change of our own.

**Rationale**: This surfaced during clarification and is the least obvious risk in the upgrade.
Verified state:

- `MissionControl::Jobs::Engine` is mounted at `/jobs` (`config/routes.rb:235`).
- `propshaft` is in the Gemfile carrying the comment `# for mission_control-jobs`.
- **`config/` contains no asset configuration at all** — no `config.assets.*` in `application.rb` or
  any environment file. The only mentions are commented-out `asset_host` examples.

So the one asset-serving surface in an API-only application inherits its entire asset configuration
from framework defaults — and Rails 8.0 makes Propshaft the default pipeline. The application code
that could break here is zero lines, which is exactly why a code-focused upgrade would miss it.

`mission_control-jobs` 1.1.0 is the latest release and declares `>= 7.1` bounds, so it does not
block resolution. Its dependency on `importmap-rails` is likewise unbounded upward.

**Why "renders" and not "responds"**: a broken stylesheet or missing script returns HTTP 200 for the
page itself. A reachability check passes while the dashboard is unusable. FR-008a and SC-013b are
worded to require an actual render.

**Also verified**: `AdminController` (the dashboard's base controller, per
`config.mission_control.jobs.base_controller_class`) authenticates via
`http_basic_authenticate_with` reading Rails credentials. This is the class that raised
`ArgumentError` in the container when credentials were unreadable. FR-008b requires its behaviour be
re-verified after the upgrade, and the container check (FR-008) is where a credentials-related
regression would show up.

---

## R6 — Framework defaults and the partner-notification guarantee

**Decision**: Adopt `load_defaults 8.0`, and **set `enqueue_after_transaction_commit` explicitly**
rather than continuing to inherit it.

**Rationale**: This is the item where the upgrade could silently undo spec 007's work.

Rails 8.0 deprecates the global `config.active_job.enqueue_after_transaction_commit`. The
application does not set it — `config/application.rb` has no such line — so it currently inherits
`:default` from `load_defaults 7.2`. That inherited value is the framework-level half of the
two-layer protection spec 007 established: a job that notifies an external partner must not be
enqueued on the strength of a database write that has not committed.

The constitution is explicit on this point (Development Workflow item 4): callers "MUST NOT rely on
that default alone where the ordering is essential to correctness — make it explicit at the call
site, so the intent survives a defaults change." **This upgrade is exactly the defaults change that
clause anticipates.** FR-014 discharges it.

The code-level layer — `Fv1::KitController` enqueuing `LalenApi::AssignKitTestsJob` after the
transaction block closes rather than inside it — is untouched by this upgrade and remains the
primary protection. Both layers are verified by the commit/rollback exercise in FR-013.

**Verified**: all 48 jobs in `app/jobs/` use `wait: :polynomially_longer` (or an explicit duration).
Zero use the removed `:exponentially_longer`. Constitution-compliant; no work needed.

**Alternatives considered**:
- *Leave defaults at 7.2* — rejected during clarification. It would leave the guarantee inherited
  from a version the app no longer runs, deferring the same decision to whoever does spec 010.

---

## R7 — `Regexp.timeout` under the new defaults

**Decision**: Verify all 6 regular-expression sites, with focused attention on the one applied to
partner-supplied input.

**Rationale**: Rails 8.0's defaults set a global regular-expression timeout. This converts a
pathological match from a hang into a raised `Regexp::TimeoutError` — a security improvement that
changes a failure mode from "slow" to "exception".

The sites, verified:

| Location | Input source | Assessment |
|---|---|---|
| `app/models/lalen_api/register_kit.rb:19` (`EMAIL_REGEXP`) | **External partner** | The one to test properly |
| `app/services/masdiag/reserved_sample_codes_creator.rb:43` (`/[oO0]/i`) | Internal | Trivial pattern, no backtracking risk |
| 4 others | Internal | Low risk |

`EMAIL_REGEXP` uses bounded quantifiers (`{0,61}`) rather than unbounded nesting, which is the
structure that resists catastrophic backtracking — so the *expected* outcome is that nothing times
out. FR-017 requires demonstrating that rather than asserting it, using valid, invalid and
unusually long inputs. An email validator on partner input is the textbook ReDoS target; being
reasonably confident is not the same as having checked.

---

## R8 — Schema file regeneration

**Decision**: Do not regenerate `db/schema.rb` as part of this upgrade unless something forces it;
if forced, regenerate only from a database at the repository's migration version.

**Rationale**: Rails 8.0 changes schema dumping to sort columns alphabetically, producing a large
but cosmetic diff on first regeneration.

The hazard is not the diff. In spec 007, a `db:schema:dump` against a development database roughly
three months behind the repository produced a *partial* dump that regressed the recorded migration
version and **deleted the `hl7_imports` and `scanned_docs` table definitions**. That is a silent,
destructive outcome from a routine-looking command, and the user's standing instruction afterwards
was to keep `db:schema:dump` out of scope.

FR-020 is written as a guard rather than a task: this is a framework upgrade, the schema must not
change, and any schema difference is a defect in the upgrade rather than a product of it. The
shared LabSample database raises the stakes — nine applications read these tables, and the user's
global rules forbid schema change there without explicit confirmation.

**Alternatives considered**:
- *Regenerate deliberately in a separate commit* — defensible in isolation and what the guide
  suggests, but it requires a development database at the repository's migration version, which is
  not currently true. Deferred, not refused.

---

## R9 — Establishing contract equivalence

**Decision**: Use the existing RSpec suite with **unchanged assertions** as the equivalence
evidence, plus a per-namespace report naming coverage gaps (FR-009, FR-009a).

**Rationale**: Settled in clarification. The suite is the only mechanism that already spans all 11
namespaces; 98 spec files assert response bodies and status codes at request level. Capturing
separate response fixtures would duplicate that for namespaces already covered, and would need a
seeded database plus new tooling.

**The honest limitation**: the suite is only as strong as its coverage, and coverage is uneven
across namespaces. Where it is thin, "the suite passes" is a correspondingly weak claim. FR-009a
requires naming those namespaces rather than letting a green run imply uniform confidence.

**The load-bearing rule**: an assertion modified to make a spec pass after the upgrade converts a
*detected* contract change into a *silent* one. FR-009 therefore treats any assertion change as a
finding requiring explanation, not as a test fix. This is the single most important discipline in
the whole upgrade, because it is the one that is easy to violate under time pressure and impossible
to detect afterwards.

**Namespace inventory** (from `config/routes.rb`, which is authoritative — the table in `CLAUDE.md`
lists nine and omits `toxo` and `diagnostyka_precyzyjna`):

`webhook`, `v1`, `fv1`, `nume`, `lalen`, `toxo`, `masdiag`, `masdiag_mailer`, `patient_portal`,
`regspec`, `diagnostyka_precyzyjna` — 11 total.

---

## R10 — Out-of-scope items, and why

| Item | Status | Reason |
|---|---|---|
| `params.expect` migration | Out | 25 `params.require` sites work unchanged; a refactor with its own risk, unrelated to the bump |
| Propshaft adoption app-wide | Out | API-only; the dashboard's use is via its own gem (R5) |
| Kamal 2 / Thruster | Out | Deployment is Docker Compose; unrelated |
| Authentication generator | Out | New-app feature; the app has working `ApiAccount` auth |
| Solid Cache / Solid Cable | Out | Not in use; Solid Queue already adopted |
| `factory_bot` 4.11 → 6.x | Out | Deferred from spec 008; still the change that would retire the `observer` shim |
| Rails 8.1 | Out | Real and current (8.1.3.1), but two minors at once conflates breaking-change sets. Candidate for spec 010 |
| `db/schema.rb` regeneration | Out | R8 |

---

## Open items carried into implementation

1. **The exact 8.0 patch may move.** 8.0.5.1 today; re-check at implementation. Spec 008 hit this
   precisely (3.4.9 → 3.4.10) and the spec's edge case anticipates it.
2. **Whether to regenerate annotations at all.** R3 recommends deferring; the diff comparison
   decides. Not a blocker either way.
3. **Which namespaces have coverage too thin to substantiate FR-009.** Determined by running the
   suite per namespace during implementation; recorded in the equivalence report.
