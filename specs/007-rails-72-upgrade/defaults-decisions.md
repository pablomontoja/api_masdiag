# Framework Defaults Decisions — `load_defaults 7.2`

**Feature**: 007-rails-72-upgrade | **Decided**: 2026-08-17
**Tasks**: T052–T058 | **Satisfies**: FR-026, FR-027, FR-029, FR-030, FR-031, SC-013, SC-014

`config.load_defaults` moved **7.1 → 7.2** in `config/application.rb:24`.

## Method note

`rails app:update` was **not** run. It is interactive, rewrites many files against a
full-stack template, and on an API-only app sharing a production database the diff
would be mostly noise requiring hunk-by-hunk rejection.

Instead the authoritative list was read from the framework itself —
`railties-7.2.3/lib/rails/application/configuration.rb`, the `when "7.2"` branch —
which is exactly what `load_defaults 7.2` applies. That yields **five** defaults, not
the sprawling template diff `app:update` implies.

## The five defaults (FR-029)

| # | Default | Value | Decision | Rationale |
|---|---------|-------|----------|-----------|
| 1 | `config.yjit` | `true` | **Adopt** | YJIT was already active at runtime (`RubyVM::YJIT.enabled? == true`) on Ruby 3.3.7; this makes it explicit configuration rather than an implicit runtime state. No behaviour change observed. |
| 2 | `active_job.enqueue_after_transaction_commit` | `:default` | **Adopt** — the consequential one | See below. |
| 3 | `active_storage.web_image_content_types` | `%w(image/png image/jpeg image/gif image/webp)` | **Adopt (inert)** | The application defines no Active Storage image variants. Attachments are PDFs, HL7 files and spreadsheets. Adopting costs nothing and avoids an unnecessary override. |
| 4 | `active_record.postgresql_adapter_decode_dates` | `true` | **Adopt (inert)** | The application uses `mysql2` in every environment. This default only affects the PostgreSQL adapter, so it is unreachable here. |
| 5 | `active_record.validate_migration_timestamps` | `true` | **Adopt** | Verified every timestamp in `db/migrate/` is in the past relative to 2026-08-17, so nothing currently violates it. Going forward it rejects future-dated migration timestamps — a useful guard for a repo where several apps contribute migrations. |

**Zero overrides.** All five adopted, so no `config.*` override lines were added
(FR-030 has nothing to record).

## Default #2 in detail — now genuinely active

This is the one with real behavioural weight, and it interacts directly with the
defect fixed in US3.

**How it resolves**: `:default` delegates to the adapter
(`activejob-7.2.3/lib/active_job/enqueue_after_transaction_commit.rb`). Solid Queue's
adapter returns `true`:

```ruby
# solid_queue-1.4.0/lib/active_job/queue_adapters/solid_queue_adapter.rb
def enqueue_after_transaction_commit?
  true
end
```

So **every job in the application** now enqueues only after the surrounding
transaction commits.

**Verified against the real Solid Queue adapter** (not the in-memory test adapter):

```
enqueue_after_transaction_commit: :default
adapter opts in?: true

  mid-txn rows:   0   (deferred to commit)
  after rollback: 0   ✅
  after commit:   1   ✅
```

Compare with the same probe **before** this change, when defaults were at 7.1:

```
enqueue_after_transaction_commit: :never
  after rollback: 1   ❌ job survived the rollback
```

**Relationship to the US3 fix**: these are now two independent layers.

- The **code fix** (`b6b5826`) moved the partner notification outside the transaction.
  It works regardless of framework defaults, and was what actually protected the Lalen
  integration between the upgrade and this change.
- This **default** provides defence-in-depth for every *other* enqueue site, including
  ones added later by developers unaware of the constraint.

Neither makes the other redundant. If this default were ever reverted, the US3 fix
would still hold the specific case that mattered.

**Impact assessment before adopting**: the five files containing both a transaction and
an enqueue were re-checked. All enqueue *after* their transaction blocks close (see
`audit-verification.md` T008), so none changes behaviour under the new default.

## API-visible behaviour (FR-031)

None. All eight in-scope namespaces re-verified after the change:

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

Full suite: **755 examples, 0 failures, 0 deprecation warnings.**

The only behavioural difference is job *timing* relative to transaction commit, which
is not observable in an HTTP response.

## Declined: full-stack capabilities (FR-027, SC-014)

Rails 7.2 also ships features aimed at full-stack applications. `api_masdiag` is
API-only (`ActionController::API`, no views, no asset pipeline for user-facing HTML),
so these are **explicitly declined**:

| Capability | Why declined |
|------------|--------------|
| Browser version guard (`allow_browser versions: :modern`) | Sets a `User-Agent` gate and renders an HTML "unsupported browser" page. Clients here are lab systems and partner servers, not browsers — this would risk rejecting legitimate API callers. |
| PWA scaffolding (`app/views/pwa/manifest.json.erb`, `service-worker.js`) | Requires a view layer and targets browser installability. Meaningless for a JSON API. |
| DevContainers (`.devcontainer/`) | A developer-experience feature, not a framework behaviour. Could be adopted independently on its merits, but is unrelated to this upgrade and would add container configuration nobody asked for. |

**Zero full-stack capabilities adopted** (SC-014 satisfied).

## Outstanding

`load_defaults 7.2` is committed separately from the version bump (`dc77b4b`), so it
can be reverted alone if a defaults-related problem surfaces in production — the
application would fall back to a supported Rails 7.2 + 7.1-defaults configuration
without touching the framework version.
