# Verification Report — Ruby 3.4.10

**Feature**: 008-ruby-34-upgrade | **Verified**: 2026-08-17
**Tasks**: T022–T034 | **Satisfies**: FR-004–FR-015, FR-019, SC-002–SC-011, SC-013

## Runtime state

| Property | Before | After |
|----------|--------|-------|
| Ruby | 3.3.7p123 | **3.4.10p104** (`+YJIT +PRISM`) |
| Rails | 7.2.3 | 7.2.3 *(unchanged — FR-013, SC-007)* |
| `load_defaults` | 7.2 | 7.2 *(unchanged)* |

## T022 — Version pin consistency (FR-005, SC-006)

| Location | Value |
|----------|-------|
| `.ruby-version` | `ruby-3.4.10` |
| `Gemfile:4` | `ruby "3.4.10"` |
| `Dockerfile:4` | `ARG RUBY_VERSION=3.4.10` |
| `Gemfile.lock` RUBY VERSION | `ruby 3.4.10p104` |

**Verdict**: ✅ all four agree.

## T023–T025 — Dependency handling

### Source-compiled gems (T024, FR-006, SC-003)

All 11 resolved at their baseline versions on the new runtime:

`mysql2 0.5.7` · `bcrypt 3.1.22` · `oj 3.17.4` · `bootsnap 1.24.6` · `msgpack 1.8.3` ·
`puma 8.0.2` · `json 2.21.1` · `racc 1.8.1` · `date 3.5.1` · `prawn 2.5.0` · `caxlsx 4.5.0`

### Precompiled gems (T025, FR-006, SC-003)

This check was added during `/speckit-analyze` because these have a **different failure mode** —
a missing platform variant for the new Ruby ABI causes a silent source fallback or resolution
failure, not a compilation error:

| Gem | Version | Resolved platform | Loads |
|-----|---------|-------------------|-------|
| `ffi` | 1.17.4 | `x86_64-linux-gnu` | ✅ |
| `nokogiri` | 1.19.4 | `x86_64-linux-gnu` | ✅ |

**Verdict**: ✅ both resolved native prebuilt binaries — no source fallback.

### Containment (FR-007, SC-008)

`bundle install` (never `bundle update`) produced a **one-line** lockfile diff:

```diff
-   ruby 3.3.7p123
+   ruby 3.4.10p104
```

**Zero gem version movement.** This is the trap spec 007 hit and the sandbox trial reproduced — an
unconstrained update would have swept in ~20 unrelated upgrades.

## T026 — Schema integrity (FR-010, SC-005)

`bin/rails db:migrate RAILS_ENV=test` produced **no change** to `db/schema.rb`.

Unlike the Rails upgrade — which restamped the format annotation `[7.1]` → `[7.2]` — a language
runtime change touches nothing in the schema dump. **Verdict**: ✅ zero LabSample schema change.

## T027 — Test suite (FR-008, SC-002, SC-013)

| Metric | Baseline (3.3.7) | After (3.4.10) |
|--------|------------------|----------------|
| Examples | 755 | **758** |
| Failures | 0 | **0** |
| Runtime | 35.92s | **38.95s** |

Example growth 755 → 758 is the three new encryption round-trip specs. **No example was lost.**

Runtime is within the SC-013 ceiling of 53.9s (+50% of baseline).

## T028 — Namespace equivalence (FR-009, SC-004)

All eight in-scope namespaces pass unchanged:

| Namespace | Examples | Failures |
|-----------|----------|----------|
| `v1/` | 12 | 0 |
| `fv1/` | 85 | 0 |
| `nume/` | 55 | 0 |
| `lalen/` | 8 | 0 |
| `masdiag/` | 13 | 0 |
| `masdiag_mailer/` | 28 | 0 |
| `regspec/` | 14 | 0 |
| `webhook/` | 12 | 0 |

Counts are identical to the pre-change figures recorded during spec 007. `patient_portal/` excluded
as dormant.

## T029 — Cross-runtime encryption (FR-011, SC-010) 🔑

**The check no spec could provide.** The suite runs entirely on one runtime, so it cannot demonstrate
that data written under 3.3.7 decrypts under 3.4.10. A probe record was persisted before the change
and read back after it:

```
reading on Ruby:   3.4.10
username:          enc_probe_008
decrypted:         {probe: "pre-ruby-34", written_on: "3.3.7"}
ciphertext opaque: true
MATCH:             true
```

**Verdict**: ✅ Lockbox-encrypted patient-adjacent data written on Ruby 3.3.7 decrypts correctly on
3.4.10, and the ciphertext never contains plaintext.

## T030–T032 — Job semantics against a real worker (FR-012, FR-019)

Verified with the real `SolidQueueAdapter`, not the in-memory test adapter (which cannot distinguish
these cases). Feasible locally because `solid_queue_db` now exists on this workstation.

```
ruby:    3.4.10
adapter: SolidQueueAdapter
enqueue_after_transaction_commit: :default

  mid-txn rows: 0   (deferred to commit)
  po commicie:  1   ✅
  po rollbacku: 0   ✅
```

**Verdict**: ✅ the post-commit enqueue semantics established in spec 007 — both the controller fix
and `load_defaults 7.2` — survive the runtime change intact.

## T033 — Container image (FR-014, SC-003, SC-011)

Built with `docker build --build-arg RUBY_VERSION=3.4.10`:

```
writing image sha256:c43c85969e23... done
naming to docker.io/library/api_masdiag:ruby34 done
```

Verified inside the image:

```
ruby 3.4.10 (2026-06-30 revision 2b0b7728dc) +YJIT +PRISM [x86_64-linux]
gemy natywne + observer: OK
nokogiri 1.19.4 platform=x86_64-linux-gnu
Rails 7.2.3 laduje sie na Ruby 3.4.10
```

**Verdict**: ✅ This closes the gap the sandbox trial could not — all source-compiled gems build
against the `-slim` toolchain, which differs from the workstation's, and the framework loads.

## T034 — Warnings (FR-015, SC-009)

| Check | Count |
|-------|-------|
| `DEPRECATION WARNING` | **0** |
| stdlib "no longer a default gem" warnings | **0** |

The `observer` warning that appeared throughout spec 007's work is gone, resolved by the declaration
in commit `1a555fa`. The three remaining `warning` matches in suite output are spec *descriptions*
containing the word, not emitted warnings.

**Verdict**: ✅ zero warnings to resolve or defer.

## Outstanding

| Item | Status |
|------|--------|
| staging/production boot | **Not verifiable from this workstation** — the DB host refuses connections here, identical on Ruby 3.3.7. FR-014 is satisfied by the container build; a full boot needs a host with database access. Inherited from spec 007. |
