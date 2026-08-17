# Feature Specification: Ruby 3.4 Upgrade

**Feature Branch**: `008-ruby-34-upgrade`

**Created**: 2026-08-17

**Status**: Draft

**Input**: User description: "przygotuj spec 008 dla Ruby 3.4" — raise the language runtime from 3.3.7 to 3.4, following the Rails 7.2 upgrade (spec 007) which deliberately deferred this as a separate feature.

## Context

Spec 007 raised the framework to Rails 7.2.3 and explicitly deferred the language runtime, on the principle of changing one variable at a time. This feature is the deferred half. It is the smaller and lower-risk of the two: no framework behaviour changes, no API surface changes, and — as measured below — no application code changes beyond a single dependency declaration.

Verified current state (branch `008-ruby-34-upgrade`, 2026-08-17):

| Property | Value |
|----------|-------|
| Ruby | 3.3.7 (pinned in `.ruby-version`, `Gemfile`, `Dockerfile`) |
| Rails | 7.2.3, `load_defaults 7.2` |
| Minimum Ruby required by Rails 7.2.3 | **`>= 3.1.0`** — 3.4 is fully supported |
| Test suite | 755 examples, 0 failures |
| Gems with native extensions | **11 source-compiled** (`mysql2`, `bcrypt`, `oj`, `bootsnap`, `msgpack`, `puma`, `json`, `racc`, `date`, `prawn`, `caxlsx`) plus **2 precompiled** (`ffi`, `nokogiri`, 8 platform variants each) — 27 lockfile entries in total |
| Deployment | Docker, `registry.docker.com/library/ruby:$RUBY_VERSION-slim` |

### Trial run already performed

Unlike spec 007, this feature begins with the upgrade already proven in a sandbox. On **Ruby 3.4.9**, with the project's `Gemfile`:

- The full dependency graph **resolved cleanly**, including the git-sourced `k-php-serialize`.
- All **11 source-compiled gems built** without error, and both precompiled gems resolved binaries for the new runtime.
- The full suite reached **755 examples, 0 failures** — matching the 3.3.7 baseline exactly.
- **Zero** deprecation warnings and zero remaining stdlib warnings.

This required exactly **one** change: declaring `observer` as an explicit dependency.

### The single blocker, already identified

Ruby 3.4 removed `observer` from the default gems. `factory_bot 4.11.1` loads it unconditionally (`lib/factory_bot/evaluation.rb:1`), so without an explicit declaration the application fails at boot:

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'factory_bot_rails'.
  Gem Load Error is: cannot load such file -- observer
```

All **97** load errors observed in the trial had this single cause. Declaring `observer` cleared every one of them.

This is the same class of problem as `csv` and `base64`, which spec 007 resolved in advance precisely to reduce this feature's scope. That work paid off: only the third and final case remains.

### Ecosystem position

`api_masdiag` at 3.3.7 is already among the most modern applications in the Masdiag fleet. The others sit on 2.7–3.2 (`rejestracja2` 2.7.8, `order-panel` 2.7.4, `indclients2`/`intranet`/`regspec` 3.0.2, `labpanel` 3.1.2, `storage` 3.2.2), several past end-of-life. There is therefore **no schedule pressure** on this particular application — Ruby 3.3 remains supported well beyond this work. The case for proceeding is that the cost is now known to be near zero, and doing it removes the last blocker from future framework upgrades.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Declare the last implicitly-relied-upon standard library dependency (Priority: P1)

Test-support code loads a standard library component that the current runtime happens to bundle but the next one does not. The developer declares it explicitly, so the application states what it actually requires rather than depending on runtime happenstance.

**Why this priority**: This is the entire blocker. It ships on the current runtime today, changes nothing observable, and removes the only obstacle to the version change. It also completes the work begun in spec 007, where the same fix was applied to two other components — leaving this one outstanding was a known, recorded gap.

**Independent Test**: Declare the dependency on the current runtime, confirm the suite still passes and behaviour is unchanged. Delivers value as completed hygiene even if the version change is never made.

**Acceptance Scenarios**:

1. **Given** test-support code that loads an undeclared standard library component, **When** the dependency list is audited, **Then** that component is identified together with the code that requires it.
2. **Given** the component is declared explicitly, **When** the suite runs on the current runtime, **Then** the result matches the recorded baseline exactly and no behaviour differs.
3. **Given** a runtime that no longer bundles the component, **When** the application loads, **Then** it resolves from the declared dependency rather than failing at require time.
4. **Given** the codebase as a whole, **When** it is scanned for other components in the same category, **Then** each is either already declared or confirmed unused.

---

### User Story 2 — Run the application on the new language runtime (Priority: P2)

The developer raises the runtime version, rebuilds native dependencies, and confirms the application behaves identically — same suite result, same API responses, same stored data.

**Why this priority**: This is the feature's actual purpose. It depends on Story 1 and cannot ship without it. It is second only because the dependency declaration must land first for the runtime change to succeed at all.

**Independent Test**: Switch the runtime, reinstall dependencies, run the full suite, and exercise the API. Success is that nothing changes except the version number.

**Acceptance Scenarios**:

1. **Given** the new runtime, **When** dependencies are resolved and installed, **Then** every native-compiled dependency builds without error.
2. **Given** the new runtime, **When** the full suite runs, **Then** it passes with zero failures and no reduction in example count relative to the baseline.
3. **Given** an authenticated request to each in-scope API namespace, **When** it is served on the new runtime, **Then** the response status and body structure match the pre-change baseline.
4. **Given** the shared LabSample database, **When** records are read and written on the new runtime, **Then** stored values are identical and no schema change occurs.
5. **Given** field-level encrypted attributes written under the previous runtime, **When** they are read on the new one, **Then** they decrypt correctly.
6. **Given** background job processing, **When** jobs are enqueued and executed, **Then** timing and outcomes match the previous runtime, including the post-commit enqueue behaviour established in the framework upgrade.
7. **Given** the runtime version is declared in more than one location, **When** the change is applied, **Then** every location states the same version.
8. **Given** the deployed container image, **When** it is built on the new runtime, **Then** the build succeeds and the application starts.

---

### User Story 3 — Resolve the remaining warning source at its root (Priority: P3)

The dependency that forced Story 1 is several major versions behind. The developer evaluates upgrading it, so the workaround can eventually be retired rather than carried indefinitely.

**Why this priority**: Genuinely optional and explicitly *not* required for the runtime change. It is recorded because declaring a compatibility shim without noting why it exists is how such shims become permanent and unexplained. Deferring is an acceptable outcome; leaving it undocumented is not.

**Independent Test**: Evaluate the newer version against the existing test-data definitions and record a recommendation. Delivers value as a decision record even if no upgrade follows.

**Acceptance Scenarios**:

1. **Given** the outdated test-support dependency, **When** its current and latest versions are compared, **Then** the breaking changes between them are recorded.
2. **Given** that assessment, **When** a decision is made, **Then** it is recorded as upgrade-now or defer-with-reason.
3. **Given** a decision to defer, **When** the compatibility declaration from Story 1 is reviewed, **Then** it carries a comment explaining what would allow its removal.

---

### Edge Cases

- **A source-compiled dependency fails to build on the new runtime.** All 11 built in the trial, but the trial machine's toolchain differs from the build container's. The container build must be verified separately, not inferred from local success.
- **A precompiled dependency has no binary for the new runtime.** `ffi` and `nokogiri` ship prebuilt binaries per platform and Ruby ABI rather than compiling. Their failure mode is a *missing variant* — a silently slower source fallback, or a resolution failure — which is different from a compilation error and must be checked as such.
- **A gem loads a removed standard library component only on a rarely-exercised path.** The suite covers what it covers; a component required inside an error handler or a seasonal report may not surface during testing. The codebase must be scanned for such requires rather than relying on a green suite alone.
- **Dependency resolution sweeps in unrelated upgrades.** Changing the runtime forces the lockfile to be recalculated, which can silently pull in unrelated newer versions — the same trap encountered during the framework upgrade, where an unconstrained resolution moved roughly forty gems. The resolution must be constrained to the runtime change.
- **The runtime version drifts between its declaration sites.** It is declared in more than one place; a divergence typically presents as working locally and failing in the deployed image.
- **Behaviour differs only under production-like settings.** Deprecation reporting is suppressed outside development and test, so warnings that appear only under production configuration can go unseen.
- **The deployed base image for the target version is unavailable or differs.** The container pulls a published image keyed to the version string; that tag must exist and provide the expected toolchain.
- **Rollback is required after deployment.** No continuous integration exists, so the change must be revertible to the exact pre-change dependency set and runtime version.

## Requirements *(mandatory)*

### Functional Requirements

**Dependency declaration**

- **FR-001**: Every standard library component that application or test-support code loads at runtime MUST be declared as an explicit dependency rather than relied upon as something the runtime bundles.
- **FR-002**: The codebase MUST be scanned for components in this category beyond the one already identified, and each MUST be either declared or confirmed unused.
- **FR-003**: Declaring these dependencies MUST NOT change behaviour on the current runtime, and MUST be independently verifiable before the version changes.

**Runtime change**

- **FR-004**: The language runtime version MUST be raised to the agreed 3.4 patch release.
- **FR-005**: The runtime version MUST be declared consistently across every location that pins it, and this consistency MUST be verified.
- **FR-006**: Every native-compiled dependency MUST build successfully on the new runtime.
- **FR-007**: Dependency resolution MUST be constrained to the runtime change; unrelated dependency upgrades MUST NOT be introduced as a side effect.
- **FR-008**: The full test suite MUST pass with zero failures and no reduction in example count relative to the recorded baseline.
- **FR-009**: Every in-scope API namespace MUST return responses equivalent in status and body structure to the pre-change baseline.
- **FR-010**: Reads and writes against the shared LabSample database MUST produce identical stored values, and no schema change MUST result.
- **FR-011**: Field-level encrypted attributes written under the previous runtime MUST decrypt correctly under the new one.
- **FR-012**: Background job behaviour MUST be verified as unchanged, including the post-commit enqueue semantics established by the framework upgrade.
- **FR-013**: The framework version MUST remain unchanged by this feature.
- **FR-014**: The deployed container image MUST build successfully on the new runtime and the application MUST start from it.
- **FR-015**: Warnings surfaced by the runtime change MUST be either resolved or individually recorded with a rationale for deferring them.
- **FR-016**: The change MUST remain revertible to the exact pre-change runtime version and dependency set.

**Follow-up assessment**

- **FR-017**: The outdated test-support dependency that necessitated the compatibility declaration MUST receive a recorded upgrade-or-defer decision.
- **FR-018**: If deferred, the compatibility declaration MUST carry an explanation of what would permit its removal.

**Verification and handover**

- **FR-019**: Verification MUST cover behaviour the automated suite cannot reach — specifically real background-job processing and production-configuration warning output.
- **FR-020**: The change MUST produce a written record of what changed, what was verified, what was deferred, and how to revert.

### Key Entities

- **Baseline record**: The measured pre-change state — example count, failure count, runtime version, framework version, and resolved dependency set. The reference for every later comparison.
- **Undeclared dependency finding**: Per standard library component — the code that requires it, whether it is declared, and the action taken.
- **Native dependency build result**: Per compiled dependency — whether it built on the new runtime, locally and in the container image.
- **Deferred item**: Anything knowingly not done — what it is, why, and what would trigger revisiting it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero standard library components remain relied upon at runtime without an explicit declaration.
- **SC-002**: The test suite passes with zero failures and no fewer than 755 examples on the new runtime.
- **SC-003**: All 11 source-compiled dependencies build successfully, both locally and inside the container image, and every precompiled platform dependency resolves a binary matching the new runtime.
- **SC-004**: All in-scope API namespaces return responses matching the pre-change baseline in status and body structure.
- **SC-005**: Zero changes to the shared LabSample database schema result from this change.
- **SC-006**: Every location declaring the runtime version states the same value.
- **SC-007**: The framework version is unchanged — it remains exactly as recorded in the baseline.
- **SC-008**: Dependency changes are limited to the runtime change and its direct consequences; zero unrelated dependency upgrades are introduced.
- **SC-009**: Every warning surfaced by the change is either resolved or recorded with a deferral rationale.
- **SC-010**: Encrypted attributes written under the previous runtime decrypt correctly under the new one.
- **SC-011**: The container image builds and the application starts from it.
- **SC-012**: Reverting to the pre-change runtime and dependency set restores the recorded baseline outcome exactly.
- **SC-013**: Test suite runtime does not regress by more than 50% relative to the recorded baseline.
- **SC-014**: A developer unfamiliar with this change can determine from the written record what changed, what was verified, what was deferred, and how to revert — without reading the diff.

## Assumptions

- **Target is Ruby 3.4, framework stays at 7.2.3.** One variable at a time, mirroring spec 007's principle. Rails 7.2.3 requires only `>= 3.1.0`, so 3.4 is supported and nothing is foreclosed.
- **The specific 3.4 patch release is a planning decision.** The trial used 3.4.9, the newest available locally; planning should confirm the newest stable patch at execution time rather than inheriting the trial's choice by default.
- **The trial is evidence, not a completed upgrade.** The sandbox run proved viability and sized the work. It was discarded; nothing was applied to the project, and every finding must be reproduced during execution.
- **`observer` is expected to be the only blocker.** Verified on 3.4.9, where declaring it cleared all 97 load errors. FR-002 still requires a fresh scan, because that conclusion could change if dependencies move before execution.
- **Upgrading the outdated test-support dependency is out of scope.** Declaring the compatibility shim is sufficient and much smaller. That upgrade spans several major versions and is its own decision.
- **No schedule pressure applies.** Ruby 3.3 remains supported well past this work, and this application is already ahead of most of the fleet. The justification is low measured cost, not urgency.
- **Scope is this application only.** Other Masdiag applications are not upgraded here, though the API-equivalence requirement exists to protect them.
- **Verification is local plus a container build.** No continuous integration exists; adding it remains an open improvement recorded against the framework upgrade, not this feature.
- **Rollback is a supported outcome.** If a native dependency or the container build fails on the new runtime, reverting and recording the blocker is a successful result, not a failure.
