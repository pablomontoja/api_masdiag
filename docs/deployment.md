# Deployment

## Docker Swarm — sekrety

Przed pierwszym deployem musisz ręcznie utworzyć sekrety w Swarmie (jednorazowo, na hoście manager node):

```bash
docker secret create masdiagapi_staging_rails_master_key config/environments/staging.key
docker secret create masdiagapi_production_rails_master_key config/environments/production.key
```

## Który Dockerfile

| Plik | Stan |
|---|---|
| `Dockerfile` | **Aktualny** — Ruby 3.4.10, Rails 8.0.5.1 |
| `Dockerfile7.0` | Relikt (Ruby 3.1.2 / Rails 7.0), niekompatybilny z obecnym `Gemfile.lock`. Nie używać |

> Wcześniejsza wersja tej listy odsyłała do `Dockerfile7.1` — taki plik **nie istnieje** w repo.

### Znany problem: kontener nie wstaje

`docker compose run app bin/rails c` kończy się:

```
admin_controller.rb:4 — Expected name: to be a String, got NilClass (ArgumentError)
```

Przyczyna: `docker-compose.yml` podaje `RAILS_MASTER_KEY` tylko w `build.args`, a nie w `environment`.
`.dockerignore` (słusznie) wyklucza klucze z obrazu, więc w runtime nie ma czym odszyfrować credentials
i `credentials.dig(:mission_control, …)` zwraca `nil`.

Poprawka — w `docker-compose.yml`:

```yaml
    environment:
      RAILS_ENV: production
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}   # z .env (gitignored)
```

Błąd występował również przed upgradem do Rails 8 — to luka konfiguracji, nie regresja.

## Kroki deployu na produkcję

1. Użyj `Dockerfile` (patrz tabela wyżej)
2. `rails db:prepare` — potrzebne dla migracji solid_queue, jeśli punkt 1 nie został wykonany
3. jeśli wystąpi problem `Specified key was too long max key length is 767 bytes` — patrz
   [runbooks/database.md](runbooks/database.md#specified-key-was-too-long-max-key-length-is-767-bytes)
   lub Masdiag Obsidian
4. `rails db:migrate:queue` — zastosowanie zmian w bazie solid_queue
5. włączenie YJIT i weryfikacja — patrz niżej

**Przed deployem sprawdź też:** [upgrades/2026-08-mariadb-rails8.md](upgrades/2026-08-mariadb-rails8.md)
— w szczególności `use_skip_locked`, które wymaga MariaDB ≥ 10.6.

### Uwagi

- `patient_portal` nie działa poprawnie — zobacz, co się dzieje przy wysłaniu żądania o wizytę
  (`DiagnostykaPrecyzyjna::AppointmentBuilderService`)

## Włączenie YJIT

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustc --version

rvm reinstall 3.4.10 --reconfigure --enable-yjit
ruby --yjit -e "p RubyVM::YJIT.enabled?"
```

W obrazie Dockera YJIT jest włączony przez `RUBYOPT="--yjit"` w `Dockerfile`.
