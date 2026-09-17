# `app:update` Review

**Feature**: 009-rails-80-upgrade | **Task**: T020 | **Date**: 2026-08-18

FR-006 forbids bulk acceptance of what the generator proposes. Every change is applied with a
reason or rejected with a reason.

## What happened

`bin/rails app:update` is interactive by default. Run non-interactively with `--force`, it
**overwrote every file it touched**, including configuration this application deliberately owns.
This is the failure mode T021/T022 exist to catch, and it caught it.

The generator's output was inspected against pre-run copies, then all overwrites were reverted with
`git checkout` and the generated migrations deleted. Only one artefact was kept.

## Disposition

| File | Generator action | Decision | Reason |
|---|---|---|---|
| `config/initializers/new_framework_defaults_8_0.rb` | create | **KEEP** | The staged-adoption mechanism. Every line stays commented out until Phase 6 (T023, FR-018) |
| `config/application.rb` | force | **REVERT** | Destroyed 20 lines of deliberate configuration — see below |
| `config/environments/{development,production,test}.rb` | force | **REVERT** | Application-owned settings; `staging.rb` isn't a generator target and was untouched |
| `config/initializers/content_security_policy.rb` | force | **REVERT** | Application-owned |
| `config/initializers/cors.rb` | force | **REVERT** | Application-owned |
| `config/initializers/filter_parameter_logging.rb` | force | **REVERT** | Security-relevant; not to be reset by a generator |
| `config/puma.rb` | force | **REVERT** | Deployment-tuned |
| `bin/dev`, `bin/setup` | force | **REVERT** | Not part of a framework bump |
| `config/initializers/assets.rb` | create then remove | n/a | Generator created and immediately removed it; API-only app |
| `app/assets/stylesheets/application.css` | remove | n/a | Did not exist |
| `db/migrate/*_active_storage.rb` (3 files) | create | **DELETE** | See below |
| `config/boot.rb`, `config/environment.rb`, `config/initializers/inflections.rb`, `bin/rails`, `bin/rake` | identical | n/a | No change proposed |

## The `application.rb` overwrite

The generator replaced the file with a stock template, discarding:

```ruby
config.autoload_paths << Rails.root.join('lib')
config.action_mailer.preview_paths << Rails.root.join("test/mailers/previews")
config.reload_classes_only_on_change = true
config.last_use_of_send_all_mail = Time.now
config.solid_queue.use_skip_locked = false
config.active_record.default_column_serializer = YAML
config.mission_control.jobs.http_basic_auth_enabled = false
config.mission_control.jobs.base_controller_class = "AdminController"
config.i18n.available_locales = [:pl, :en]
config.i18n.default_locale = :en
```

Several of these are load-bearing. Losing `default_column_serializer = YAML` would change how
serialized columns are read; losing the `mission_control.jobs.*` pair would break the `/jobs`
dashboard's authentication wiring; losing the locale configuration would undo the work verified in
T017c. It also rewrote `autoload_lib(ignore: %w(tasks))` to `%w[assets tasks]`.

**Reverted in full.** Verified afterwards: all 8 deliberate settings present, `load_defaults` still
at 7.2 (Phase 6 raises it deliberately, not as a side effect).

## The Active Storage migrations

`app:update` ran `active_storage:update`, generating three migrations:

- `add_service_name_to_active_storage_blobs`
- `create_active_storage_variant_records`
- `remove_not_null_on_active_storage_blobs_checksum`

**Deleted, all three.** FR-020 and invariant I1 forbid schema change in this upgrade, and the user's
standing rules forbid altering shared `LabSample` tables without explicit confirmation — nine
applications read that database. These migrations are also not new to Rails 8; they date from
Active Storage changes in 6.0/6.1 and have simply never been applied here. Whether this application
needs them is a separate question with its own risk assessment, and it is not this upgrade's to
answer.

## Net result

```
 M Gemfile
 M Gemfile.lock
?? config/initializers/new_framework_defaults_8_0.rb
```

The framework bump changed two dependency manifests and added one inert initializer. No application
code, no configuration, no schema.

## Lesson

`app:update --force` is not a safe non-interactive equivalent of `app:update`. It answers "yes" to
every overwrite prompt, including for files the application owns. Anyone repeating this should
either run it interactively or, as here, run it against a clean tree and use `git checkout` to
reject overwrites file by file.
