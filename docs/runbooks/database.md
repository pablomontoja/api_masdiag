# Runbook: baza danych

## Przygotowanie bazy testowej

```bash
rails db:schema:dump
rails tmp:clear
RAILS_ENV=test rails db:drop db:create db:schema:load
```

> **⚠️ Uwaga do `db:schema:dump`.** Uruchamiaj **wyłącznie** z bazy deweloperskiej będącej na
> tej samej wersji migracji co repo. W spec 007 dump z bazy zapóźnionej o ~3 miesiące wygenerował
> częściowy zrzut, który **skasował definicje tabel `hl7_imports` i `scanned_docs`** oraz cofnął
> `define(version: …)` do starszej migracji. Zmiany trzeba było wycofać przez `git checkout db/schema.rb`.
>
> Sprawdź przed uruchomieniem:
> ```bash
> bin/rails runner 'puts ActiveRecord::Migrator.current_version'
> grep -oE "define\(version: [0-9_]+\)" db/schema.rb
> ```
> Jeśli wartości się różnią — najpierw `db:migrate`, dopiero potem dump.
>
> Rails 8.0 dodatkowo sortuje kolumny alfabetycznie przy zrzucie, więc pierwszy dump po upgradzie
> wygeneruje duży diff kosmetyczny. To osobna zmiana, nie mieszać jej z inną pracą.

## Przeładowanie schematu w trakcie migracji

```ruby
Test.reset_column_information
```

## Uruchamianie migracji z konsoli Rails

```ruby
require Rails.root.join('db/migrate/20260311113835_toxicology_quant_project')
ToxicologyQuantProject.new.change
```

## Problemy

### Specified key was too long; max key length is 767 bytes

Open my.ini and add this lines(if they already exist just edit everything after =) right after [mysqld]:

```
innodb_file_format = Barracuda
innodb_file_per_table = on
innodb_default_row_format = dynamic
innodb_large_prefix = 1
innodb_file_format_max = Barracuda
```

OR

Autenticate to mysql:

```
mysql -h localhost -u root
```

or use phpmyadmin.

Once you're authenticated run this queries(one at a time):

```
SET GLOBAL innodb_file_format = Barracuda;
SET GLOBAL innodb_file_per_table = on;
SET GLOBAL innodb_default_row_format = dynamic;
SET GLOBAL innodb_large_prefix = 1;
SET GLOBAL innodb_file_format_max = Barracuda;
```

## Współdzielona baza LabSample

Bazę `LabSample` czyta i zapisuje dziewięć aplikacji (`rejestracja2`, `indclients2`, `labpanel`,
`api_masdiag`, `order-panel`, `ifirma_api`, `intranet`, `storage`, plus C#-owy `labsample`).

**Nie zmieniaj schematu tabel LabSample** — kolumn, tabel, indeksów, ograniczeń — bez wcześniejszego
sprawdzenia wpływu na pozostałe aplikacje. Zmiana wyglądająca lokalnie bezpiecznie potrafi zepsuć
inny system.

Nie dotyczy to `regspec` i `msdg_inspection`, które mają własne, odizolowane bazy.

Kolejka Solid Queue używa **osobnej bazy** `solid_queue_db` (`config/database.yml`, wpis `queue`,
migracje w `db/queue_migrate`).
