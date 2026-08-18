# api_masdiag

Rails 8 API-only — centralne API ekosystemu Masdiag (laboratorium diagnostyczne).
Multi-tenant, 11 namespace'ów, współdzielona baza LabSample.

## Szybki start

```bash
rvm use 3.4.10
bundle install
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test

bundle exec rspec        # 758 examples, 0 failures
bin/rails s
```

Kolejka zadań (osobny proces):

```bash
bin/rails solid_queue:start
```

## Stack

| | |
|---|---|
| Ruby | 3.4.10 (+YJIT +PRISM) |
| Rails | 8.0.5.1 (API-only) |
| Baza | MariaDB 10.11 — `LabSample` (primary) + `solid_queue_db` (queue) |
| Kolejki | Solid Queue (nie Sidekiq) |
| Serializacja | Alba (`app/resources/*Resource`) |
| Szyfrowanie | Lockbox (pola wrażliwe) |
| Pliki | MinIO / Active Storage |
| Testy | RSpec + FactoryBot (bez fixtures) |

## Dokumentacja

| Temat | Plik |
|---|---|
| Deployment, Docker Swarm, YJIT | [docs/deployment.md](docs/deployment.md) |
| **Upgrade MariaDB 10.11 + Rails 8.0** | [docs/upgrades/2026-08-mariadb-rails8.md](docs/upgrades/2026-08-mariadb-rails8.md) |
| Baza: test DB, migracje, problemy | [docs/runbooks/database.md](docs/runbooks/database.md) |
| Operacje na próbkach (LALEN, QNS, transfery) | [docs/runbooks/samples.md](docs/runbooks/samples.md) |
| Raporty i eksporty, walidacja LSI | [docs/runbooks/reports.md](docs/runbooks/reports.md) |
| Workflow dla partnerów API | [docs/api/partner-workflow.md](docs/api/partner-workflow.md) |
| Namespace `masdiag` | [docs/masdiag/README.md](docs/masdiag/README.md) |
| Namespace `masdiag_mailer` | [docs/masdiag_mailer/README.md](docs/masdiag_mailer/README.md) |
| Architektura, konwencje, zasady pracy | [CLAUDE.md](CLAUDE.md) |
| Specyfikacje zmian (spec-kit) | `specs/` |

## ⚠️ Przed deployem na produkcję

1. **`use_skip_locked` czeka na potwierdzenie wersji MariaDB.** Wymaga ≥ 10.6; obecnie wyłączone.
   Sprawdź `SELECT VERSION()` **na bazie `solid_queue_db`**, nie na `LabSample`.
   → [szczegóły i pomiar](docs/upgrades/2026-08-mariadb-rails8.md)

2. **`docker-compose.yml` nie podaje `RAILS_MASTER_KEY` w `environment`** — kontener nie wstaje.
   → [opis i poprawka](docs/deployment.md#znany-problem-kontener-nie-wstaje)

3. **Brak unique indexu na `notes`** — wyścig dwóch jobów może wysłać ten sam e-mail dwa razy.
   → [lista otwartych kwestii](docs/upgrades/2026-08-mariadb-rails8.md#nadal-otwarte-zweryfikowane-w-kodzie-2026-08-18)

4. Pełna checklista kroków deployu → [docs/deployment.md](docs/deployment.md#kroki-deployu-na-produkcję)

## TODO

- new layout for /rails/mailers/cancellation_notification_mailer/send_mail_to_contractor
- new layout for /rails/mailers/cancellation_notification_mailer/send_mail_to_patient
- new layout for /rails/mailers/cancellation_notification_mailer/standard_cancellation_notification
- new layout for /rails/mailers/result_notification_mailer/contractor_result_notification_mailer
- new layout for /rails/mailers/result_notification_mailer/patient_result_notification_mailer_lekam
