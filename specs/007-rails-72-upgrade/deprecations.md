# Deprecation Report

**Feature**: 007-rails-72-upgrade | **Verified**: 2026-08-17
**Tasks**: T038–T041 | **Satisfies**: FR-024, FR-025, SC-012

## Result

**Zero Rails deprecation warnings remain** after the upgrade to 7.2.3.

## Resolved

### 1. `serialize` positional coder → keyword (FR-025)

`app/models/key_value_db_store.rb:5`

```diff
-  serialize :json, ::ActiveRecord::Coders::JSON
+  serialize :json, coder: ::ActiveRecord::Coders::JSON
```

The three sites in `app/models/shop_order.rb` already used `type:` and needed no change.

### 2. `ActiveRecord::Base.connection` → `with_connection` (FR-025)

Deprecated in 7.2 in favour of explicitly scoped connection leases.

`db/migrate/20260311113835_toxicology_quant_project.rb` — both calls wrapped in a
single block, since they are two halves of one operation (read max id, then set
`AUTO_INCREMENT`) and should share a lease:

```diff
-    result = ActiveRecord::Base.connection.execute("SELECT COALESCE(MAX(...)")
-    next_id = result.first.first
-    ActiveRecord::Base.connection.execute("ALTER TABLE ... AUTO_INCREMENT = #{next_id}")
+    ActiveRecord::Base.with_connection do |conn|
+      result = conn.execute("SELECT COALESCE(MAX(...)")
+      next_id = result.first.first
+      conn.execute("ALTER TABLE ... AUTO_INCREMENT = #{next_id}")
+    end
```

`spec/services/hl7/measurement_importer_spec.rb:57` — same transformation.

### 3. Legacy hash-syntax `enum` declarations

Surfaced by 7.2 as:

> `DEPRECATION WARNING: Defining enums with keyword arguments is deprecated and will be removed in Rails 8.0.`

Two sites, exactly as the audit predicted:

```diff
-  enum status: { ready: 0, ocr_pending: 1, transcribed: 2, failed: 9 }   # scanned_doc.rb:7
+  enum :status, { ready: 0, ocr_pending: 1, transcribed: 2, failed: 9 }

-  enum material_type: MaterialTypes::MODEL_HASH                          # test.rb:27
+  enum :material_type, MaterialTypes::MODEL_HASH
```

**Scope note**: this is a **Rails 8.0** removal, not a 7.2 one — the upgrade would
ship without it. It was fixed anyway because it is a two-line mechanical change,
it was the only deprecation output the upgrade produced, and leaving it would mean
carrying known-removed syntax into the next upgrade. Every other model already used
the keyword form, so this also restores internal consistency.

## Deferred

### `observer` no longer a Ruby default gem

```
factory_bot-4.11.1/lib/factory_bot/evaluation.rb:1: warning: observer.rb was loaded
from the standard library, but will no longer be part of the default gems starting
from Ruby 3.4.0.
```

**Deferred to the Ruby 3.4 feature.** Rationale:

- It is a **Ruby** warning, not a Rails one — out of scope for this upgrade.
- The source is `factory_bot 4.11.1`, a **test-only** dependency, so production is
  unaffected.
- It is the same class of problem as `csv`/`base64` (handled in US2), and belongs
  with them in the Ruby 3.4 work.

**Revisit trigger**: the Ruby 3.4 upgrade spec. Either declare `observer` explicitly
or upgrade `factory_bot`, which is several major versions behind (4.11 vs current 6.x)
and is its own decision.

## Verification

| Check | Result |
|-------|--------|
| Suite after cleanup | **755 examples, 0 failures** |
| `DEPRECATION WARNING` count | **0** |
| Ruby stdlib warnings | 1 (`observer`, deferred with rationale) |
