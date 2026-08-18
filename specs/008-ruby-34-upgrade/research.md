# Phase 0 Research: Ruby 3.4 Upgrade

**Feature**: 008-ruby-34-upgrade | **Date**: 2026-08-17

The spec deferred two decisions to planning and carried forward evidence from a sandbox trial.
This phase resolves both decisions and records what the trial does and does not prove.

---

## R1 — Target patch release: **3.4.10**, not the trial's 3.4.9

**Decision**: Target **Ruby 3.4.10**.

**Finding**: The spec deliberately declined to inherit the trial's version, and that caution was
warranted. Querying Docker Hub's published tags shows 3.4.10 has since been released:

```
3.4.6-slim  3.4.7-slim  3.4.8-slim  3.4.9-slim  3.4.10-slim
3.4.11-slim → 404 (does not exist)
3.5.0-slim  → 404 (does not exist)
```

3.4.10 is the newest published patch in the series. Patch releases within a stable minor are
backward compatible, so the trial's evidence on 3.4.9 carries forward — but it is *evidence for
the series*, not proof for this exact build.

**Consequence for the plan**: the suite must be re-run on 3.4.10 rather than treating the 3.4.9
trial as the verification. This is a re-run, not new work.

**Local availability gap**: 3.4.10 is **not installed** on this workstation (3.4.4 and 3.4.9 are),
and RVM's known-list is stale — `rvm list known | grep 3.4` returns nothing, so `rvm install 3.4.10`
would fail until `rvm get stable` refreshes it. This is a real prerequisite step, not an assumption.

**Alternatives considered**:
- *3.4.9* — matches the trial exactly, requires no RVM refresh. Rejected: knowingly targeting a
  superseded patch on a security-sensitive application is the wrong default when the newer one is
  published and the delta is a compatible patch.
- *Ruby 3.5* — does not exist yet (404). Not an option.

---

## R2 — Container base image

**Decision**: `registry.docker.com/library/ruby:3.4.10-slim`, matching the existing Dockerfile pattern.

**Finding**: The Dockerfile parameterises the version:

```dockerfile
ARG RUBY_VERSION=3.3.7
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base
```

so the image change is a single `ARG` edit. Verified `ruby:3.4.10-slim` exists and returns HTTP 200
on Docker Hub.

**Consequence**: FR-014 (container builds, application starts) is satisfiable, and the `-slim`
variant is unchanged — so the toolchain available for native compilation is the same family as today.
That does **not** prove the 27 native gems compile *inside* the image; the trial proved only local
compilation against the workstation toolchain. The container build is a separate verification.

---

## R3 — What the trial proves, and what it does not

**Decision**: Treat the trial as sizing evidence, re-verify everything at execution.

The sandbox run on Ruby 3.4.9 established:

| Proven | Evidence |
|--------|----------|
| Dependency graph resolves | `bundle lock` succeeded, git-sourced gem included |
| All 27 native gems compile **locally** | `bundle install` succeeded |
| Suite passes | **755 examples, 0 failures** — matches the 3.3.7 baseline |
| Zero deprecations, zero stdlib warnings | suite output |
| Exactly one declaration needed | `observer` |

**Not proven, and therefore planned as real work**:

1. **Compilation inside the build container** — the trial used the workstation toolchain, not
   `ruby:3.4.10-slim`. Different base, different headers.
2. **Behaviour on 3.4.10** specifically (see R1).
3. **Whether `observer` is still the only blocker** — dependencies may have moved. FR-002 mandates
   a fresh scan.
4. **Real background-job behaviour** — the suite uses the in-memory test adapter, which cannot
   demonstrate the post-commit enqueue semantics that spec 007 established.
5. **Encrypted-attribute round-trip** — Lockbox 2.2.0 was verified on Ruby 3.3.7, not 3.4.

---

## R4 — The `observer` declaration

**Decision**: Declare `gem "observer"` in the main dependency group, with a comment naming the cause.

**Finding**: Ruby 3.4 removed `observer` from the default gems. `factory_bot 4.11.1` requires it
unconditionally at `lib/factory_bot/evaluation.rb:1`. Without the declaration the application fails
at boot:

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'factory_bot_rails'.
  Gem Load Error is: cannot load such file -- observer
```

All **97** load errors in the trial resolved to this one cause.

**Placement**: `factory_bot_rails` is in the `:test` group, so `observer` could arguably go there
too. It is declared in the **main group** instead, matching how spec 007 declared `csv` and `base64`
— those are required by application code, and keeping all three stdlib declarations together makes
the category legible. A `:test`-only placement would also work but splits a single concern across
two groups.

**Alternatives considered**:
- *Upgrade `factory_bot` 4.11 → 6.x* — removes the need for the shim entirely, but spans several
  major versions and would change test-data definitions across the suite. Out of scope; recorded as
  User Story 3 (P3).
- *Vendor or patch factory_bot* — disproportionate for a one-line declaration.

---

## R5 — Constraining dependency resolution ⚠️

**Decision**: Add `observer` in a **separate commit on Ruby 3.3.7** using plain `bundle lock`, then
change the runtime version without a general dependency update.

**Finding**: This is the trap spec 007 hit and documented, and the trial reproduced it. The trial ran
`bundle lock --update` unconstrained, which resolved successfully while sweeping in roughly twenty
unrelated upgrades:

| Gem | Was | Unconstrained update |
|-----|-----|----------------------|
| `alba` | 3.10.0 | 3.11.0 |
| `oj` | 3.17.4 | 3.17.6 |
| `rack` | 3.2.6 | 3.2.7 |
| `aws-sdk-s3` | 1.227.0 | 1.229.0 |
| `bootsnap`, `groupdate`, `json`, `net-imap`, … | — | newer |

Any failure after that would be unattributable, and FR-016's revert guarantee compromised.

**Sequencing constraint** (identical to spec 007 R5): `bundle lock --conservative --update <gems>`
**cannot add a gem absent from the lockfile**. Adding `observer` therefore requires a plain
resolution pass, which must happen as its own commit *before* the runtime changes — exactly what
User Story 1 already describes.

**Expected diff for that commit**: one `observer` line in `GEM`, one in `DEPENDENCIES`. Nothing else
should move, mirroring the `csv` result in spec 007 (a 3-line lockfile diff).

**After the runtime change**: the lockfile records `RUBY VERSION`, so it must be regenerated — but
via `bundle install` on the new runtime, not `bundle update`. Any gem version movement in that diff
is a signal to stop and investigate.

---

## R6 — Verification approach

**Decision**: Local verification plus a container build. No staging deployment.

**Rationale**: Carried over from spec 007's clarified decision. The consequence is unchanged: with no
deployment soak, job behaviour and encryption must be exercised **deliberately** against a real
worker and real records, or they will not be exercised at all.

**Newly reachable since spec 007**: `solid_queue_db` now exists locally, so real-adapter job
verification can run in the development environment without the remote host.

**Still unreachable**: staging and production boot. Both resolve a database host that refuses
connections from this workstation — an environmental limit, not a runtime defect, and identical on
Ruby 3.3.7. FR-014 is satisfied by the container **build**; a full staging boot remains an
outstanding pre-release check inherited from spec 007.

---

## Residual unknowns

None blocking. One item deliberately deferred to execution:

- **Whether `factory_bot` should be upgraded** (User Story 3, P3). Requires assessing breaking
  changes across 4.x → 6.x against the existing factory definitions. Deferring is an acceptable
  outcome provided the `observer` declaration carries an explanation of what would retire it.
