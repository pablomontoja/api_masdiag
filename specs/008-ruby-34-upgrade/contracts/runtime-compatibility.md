# Contract: Behaviour Preservation Across the Runtime Change

**Feature**: 008-ruby-34-upgrade | **Date**: 2026-08-17

## What this contract asserts

This change defines **no new interface**. As with spec 007, the contract is inverted: it asserts that
everything observable stays the same while the language runtime underneath it changes.

For every in-scope endpoint, given an identical authenticated request, Ruby 3.4.10 must return a
response whose **HTTP status and body structure** are identical to those produced on Ruby 3.3.7.

## Scope

**In scope — 8 namespaces** (unchanged from spec 007):

| Namespace | Request specs |
|-----------|---------------|
| `v1/` | 12 |
| `fv1/` | 85 |
| `nume/` | 55 |
| `lalen/` | 8 |
| `masdiag/` | 13 |
| `masdiag_mailer/` | 28 |
| `regspec/` | 14 |
| `webhook/` | 12 |

**Out of scope**: `patient_portal/` — dormant, two read-only endpoints, implementation expected to
change. Excluded by clarification during spec 007; that exclusion still holds.

Unlike spec 007, **no new namespace coverage is needed**. `regspec` gained its smoke checks then, so
every in-scope namespace already has a before-state to compare against.

## Equivalence definition

Two responses are equivalent when:

1. **HTTP status matches exactly.**
2. **Body structure matches** — same keys, nesting, types, array ordering semantics.
3. **Error responses match** — the `ExceptionHandler` 404/422 JSON shape is part of the contract.
4. **Auth failures match** — unauthenticated and unauthorized requests fail identically.

Volatile values (timestamps, generated ids, counts dependent on test data) are not part of the
contract. Structure and status are.

## Behavioural surfaces that must not change

Beyond HTTP responses, four behaviours are explicitly in scope because a runtime change could
plausibly affect them and a green suite would not necessarily reveal it.

### 1. Field-level encryption (FR-011, SC-010)

Lockbox 2.2.0 was verified against Active Record 7.2.3 on **Ruby 3.3.7**. A runtime change replaces
the host for that library's cryptographic operations.

**Contract**: data written under Ruby 3.3.7 decrypts correctly under 3.4.10, and ciphertext remains
opaque (never contains plaintext).

**Verification**: write an encrypted attribute before the change, read it after. A round-trip
performed entirely on the new runtime would not prove cross-runtime compatibility — the check must
span both.

### 2. Background job semantics (FR-012, FR-019)

Spec 007 established that jobs enqueued inside a transaction must not reach the queue unless that
transaction commits — enforced both by the code fix in `Fv1::KitController` and by
`load_defaults 7.2`.

**Contract**: on Ruby 3.4.10, a committed transaction produces exactly one partner notification; a
rolled-back transaction produces none.

**Verification**: against a **real Solid Queue worker**, not the in-memory test adapter, which cannot
distinguish these cases. Now feasible locally — `solid_queue_db` exists on this workstation.

### 3. Shared database interaction (FR-010, SC-005)

**Contract**: reads and writes against LabSample produce identical stored values, and no schema
change results. Other applications in the ecosystem read the same tables.

**Watch item**: `db/schema.rb` carries a format annotation tied to the *Rails* version, not Ruby, so
a runtime change alone should leave it untouched. Any diff there is a signal to investigate, not to
commit.

### 4. Container startup (FR-014, SC-011)

**Contract**: `ruby:3.4.10-slim` builds the image successfully, all source-compiled gems build inside
it, and the application starts.

**Why separate from local verification**: the sandbox trial compiled gems against the workstation
toolchain. The `-slim` image has a different, more minimal one. Local success does not imply
container success.

## Verification method

Given local-only verification (clarified during spec 007):

1. **Before the change** — record the suite result on Ruby 3.3.7 (expect 755 examples, 0 failures) and
   write the encryption round-trip check so it captures a genuine before-state.
2. **After the change** — rerun; every previously passing example must still pass with no reduction
   in count.
3. **Job timing** — exercise the commit and rollback paths deliberately against a real worker. With
   no deployment soak, these are only exercised on purpose.
4. **Encryption** — read the pre-change encrypted record on the new runtime.
5. **Container** — build the image and start the application from it.

## Known gap

**Staging and production boot cannot be verified from this workstation.** Both resolve their database
host from credentials, and that host refuses connections here — an environmental limit, identical on
Ruby 3.3.7, not a defect of this change.

FR-014 is satisfied by a successful **container build**. A full staging boot remains an outstanding
pre-release action inherited from spec 007, and this feature does not close it.
