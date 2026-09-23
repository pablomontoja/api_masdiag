# Quickstart: Project and User Attribute Translation

No external API contracts are introduced by this feature (no new/changed endpoints, serializers, or request/response shapes) — it is confined to two model files and one data migration, so `contracts/` is intentionally omitted. This quickstart instead documents how to manually verify the feature once implemented.

## Prerequisites

```bash
rvm use 3.4.10
bin/rails db:migrate RAILS_ENV=development
```

## Verify Project translation (read/write)

```bash
rvm use 3.4.10 && bin/rails runner '
project = Project.find(2) # Witamina D

I18n.with_locale(:pl) { puts "PL: #{project.Name}" }        # => "Witamina D"
I18n.with_locale(:en) { puts "EN: #{project.Name}" }        # => "Vitamin D metabolites" (after migration)

# Ordinary writes (no explicit locale: kwarg) ALWAYS land in the native column,
# regardless of ambient I18n.locale — the app default locale is :en, and this
# must not require every caller to wrap in I18n.with_locale(:pl) to be safe.
project.update!(Name: "Test PL")
puts "Native column: #{project.reload.read_attribute(:Name)}" # => "Test PL"
puts "PL translation rows: #{project.string_translations.where(key: "Name", locale: "pl").count}" # => 0

# Writing an English translation REQUIRES an explicit locale: keyword argument.
project.public_send(:Name=, "Test EN", locale: :en)
project.save!
puts "Native column unchanged: #{project.reload.read_attribute(:Name)}" # => "Test PL"
puts "EN translation value: #{project.string_translations.find_by(key: "Name", locale: "en")&.value}" # => "Test EN"
'
```

## Verify the backfill migration ran for all 47 Projects

```bash
rvm use 3.4.10 && bin/rails runner '
missing = I18n.with_locale(:en) { Project.all.select { |p| p.Name.blank? } }
puts missing.any? ? "MISSING EN NAME: #{missing.map(&:Id)}" : "All Projects have an English name"
'
```

## Verify migration idempotency

```bash
rvm use 3.4.10 && RAILS_ENV=development bin/rails runner '
before = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM mobility_string_translations WHERE translatable_type = \"Project\" AND locale = \"en\"").first[0]
puts "Before: #{before}"
'
bin/rails db:migrate:redo:primary VERSION=20260923120000   # namespaced task name (multi-database app)
rvm use 3.4.10 && RAILS_ENV=development bin/rails runner '
after = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM mobility_string_translations WHERE translatable_type = \"Project\" AND locale = \"en\"").first[0]
puts "After: #{after}"
'
# Expect before == after == 47
```

## Verify User model readiness has zero behavior change

```bash
rvm use 3.4.10 && bin/rails runner '
user = User.first
I18n.with_locale(:pl) { puts user.FirstName }   # unchanged, reads native column
I18n.with_locale(:en) { puts user.FirstName }   # falls back to native column value (no EN row exists)
puts "Translation rows for this user: #{user.string_translations.count}" # => 0
'
```

## Run the test suite

```bash
bundle exec rspec spec/models/project_spec.rb spec/models/analyte_spec.rb spec/models/user_spec.rb
bundle exec rspec   # full suite — must remain green (Constitution Principle III / FR-014)
```
