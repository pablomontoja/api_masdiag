# Upgrade 2026-08: MariaDB 10.11 + Rails 8.0


Kontekst: lokalnie Rails 7.2.3 → 8.0.5.1 (gałąź `009-rails-80-upgrade`), równolegle MariaDB 10.x → 10.11.
Sprawdzone na `10.11.18-MariaDB-ubu2204`, mysql2 0.5.7, klient 3.3.17.

## ⚠️ Wymaga MariaDB ≥ 10.6 na produkcji — NIE włączać wcześniej

**`config.solid_queue.use_skip_locked`** (`config/application.rb`) — obecnie `false`,
wyłączone w commicie `b0f2e39` pod starszą MariaDB. Domyślna wartość gemu to `true`.
`FOR UPDATE SKIP LOCKED` istnieje od MariaDB 10.6.

Pomiar na dwóch równoległych wątkach sięgających po ten sam wiersz kolejki:

| ustawienie | t1 | t2 | czas oczekiwania t2 |
|---|---|---|---|
| `false` (obecnie) | `[3]` | `[3]` | **1.28 s** — blokuje się, pobiera ten sam wiersz |
| `true` | `[3]` | `[4]` | **0.02 s** — pomija zablokowany, bierze następny |

W `config/queue.yml` działa min. 3 procesy (`JOB_CONCURRENCY=2` + worker `mailers`), więc
obecnie serializują się na blokadach.

**Kolejność na produkcji:**
1. `SELECT VERSION();` **na bazie `solid_queue_db`** (nie na `LabSample` — to osobna baza)
2. dopiero gdy ≥ 10.6 → `config.solid_queue.use_skip_locked = true` (albo usunąć linię, `true` jest domyślne)
3. restart workerów

Włączenie przy starszej MariaDB wywali workery przy pobieraniu zadań.

## Zweryfikowane — działa bez zmian

- pełny suite **758 examples, 0 failures**
- `mariadb?` = true, `database_version` = 10.11.18 wykrywane poprawnie
- INSERT zwraca id, rollback działa, composite PK (`AnalyteResult`) OK
- polskie znaki i znaki 4-bajtowe (emoji) round-trip poprawnie
- `db/schema.rb` bez zmian, brak pending migrations

## Nowość w 10.11: `INSERT ... RETURNING`

`supports_insert_returning?` = **true** (MariaDB ≥ 10.5). Rails używa `INSERT ... RETURNING`
zamiast `last_insert_id()`. Dotyczy modeli z nietypowym PK:

- `AnalyteResult` — composite `["ResultId", "AnalyteId"]`
- `Result`, `PlateMeasurement`, `OnlineFile` — PK bez auto_increment

Sprawdzone: `auto_populated?` = `nil` dla non-autoincrement, Rails nie próbuje ich odczytywać.
Działa poprawnie, ale **to jedyne miejsce wchodzące w inną ścieżkę kodu niż starsze 10.x** —
tam szukać, gdyby coś się posypało po deployu.

## Kolacje — stan zastany, NIE regresja po upgradzie

```
utf8mb3_polish_ci   172 kolumny
utf8mb3_general_ci  151 kolumn
utf8mb4_general_ci    5 kolumn
```

Skutek — `ORDER BY LastName` na `Patients` (kolumna `utf8mb3_general_ci`) nie sortuje po polsku:

```
general_ci:  Żaba, Zbigniew, Zenon     ← Ż przed Z
polish_ci:   Zbigniew, Zenon, Żaba     ← poprawnie
```

To pozostałość po C#-owym LabSample — `db/schema.rb` sprzed upgradu ma te same kolacje.
Upgrade 10.11 tego nie zmienił. `database.yml` deklaruje `encoding: utf8mb4` przy bazie
`utf8mb3` — działa, ale znaki 4-bajtowe mogą zostać odrzucone przez kolumny `utf8mb3`.

## Do sprawdzenia na produkcji przed deployem

```sql
SELECT VERSION();                     -- osobno na LabSample i solid_queue_db
SHOW VARIABLES WHERE Variable_name IN ('sql_mode','collation_server','collation_database');
```

Lokalnie `sql_mode` zawiera `STRICT_TRANS_TABLES,STRICT_ALL_TABLES` — jeśli produkcja ma inny,
walidacje mogą zachować się inaczej. Nie sprawdzano wydajności: 10.11 zmienił optymalizator,
więc ciężkie raporty (`MasdiagRecurring::Monthly::*`) mogą mieć inne plany zapytań.

## Pozostałe z upgradu Rails 8.0 (nie związane z bazą)

- **`docker-compose.yml`** — brakuje `RAILS_MASTER_KEY` w sekcji `environment` (jest tylko
  w `build.args`). Kontener nie wstaje: `admin_controller.rb:4 — Expected name: to be a String,
  got NilClass`. Błąd **sprzed** upgradu, nie regresja
- **`annotate` → `annotaterb`** — `annotate` 3.2.0 to ostatnie wydanie i blokuje Rails 8.
  Uwaga: Bundler **nie** zgłasza błędu, tylko po cichu schodzi do `annotate` 2.6.5 (z 2014).
  Konfiguracja w `.annotaterb.yml`, `skip_on_db_migrate: true` — po zmianie schematu
  odpalać `bundle exec annotaterb models` ręcznie
- **`enqueue_after_transaction_commit`** — globalny config jest deprecated w 8.0 i usunięty
  w 8.1; ustawiony per-job na `LalenApi::AssignKitTestsJob` i `RegisterKitJob`

Pełna dokumentacja: `specs/009-rails-80-upgrade/upgrade-record.md`

## Nadal otwarte (zweryfikowane w kodzie 2026-08-18)

Pozostałości z review 2026-07-27, które sprawdziłem i **wciąż obowiązują**:

- **Brak unique indexu na `notes`** — idempotencja `Notifications::Sender` opiera się wyłącznie
  na walidacji aplikacyjnej. W `db/schema.rb` są tylko indeksy `["key"]` i
  `["subject_type","subject_id"]`, żaden nie jest `unique` → wyścig dwóch równoległych jobów
  nadal może wysłać ten sam e-mail dwa razy
- **`Dockerfile7.0`** wciąż leży obok głównego `Dockerfile` — obraz Ruby 3.1.2/Rails 7.0,
  niekompatybilny z obecnym `Gemfile.lock` (wymaga 3.4.10). Ryzyko przypadkowego użycia
- **`StockRoomItem belongs_to :stock_room`** bez `optional: true` — zapis bez `stock_room_id`
  kończy się błędem walidacji (422)
- **`delayed_job_active_record`** nadal w Gemfile jako drugi system kolejek obok Solid Queue,
  tylko dla `DelayedJobsMonitoringJob`
- **`hl7_imports`** ma `utf8mb3/utf8mb3_polish_ci` — poza BMP dane HL7 mogą być obcinane
  (patrz sekcja o kolacjach wyżej)
- **`composite_primary_keys`** zakomentowany w Gemfile — działa, bo Rails 7.1+ ma natywne
  wsparcie (`AnalyteResult` używa `self.primary_key = ["ResultId","AnalyteId"]`)
- **Migracja `20260718184044`** ma timestamp 2026 zamiast 2025 — kosmetyka, psuje chronologię

Nieaktualne z tamtego review: `validate_confirmation_test_request` **nie jest** martwym kodem —
wywoływane w `fv1/sample_controller.rb:60` i `lalen/sample_controller.rb:65`.
