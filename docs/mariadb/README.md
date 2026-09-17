# MariaDB upgrade log

## 10.1 → 10.2 (zweryfikowane lokalnie 2026-08-17, wynik: 10.2.44-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.1-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.1` → `mariadb:10.2`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.2.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u

## 10.2 → 10.3 (zweryfikowane lokalnie 2026-08-17, wynik: 10.3.39-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.2-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.2` → `mariadb:10.3`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
   (bez tego kroku start kończy się błędem `Incorrect definition of table mysql.event`
   i wyłączeniem Event Schedulera — normalne po majorowym skoku, naprawia mysql_upgrade)
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.3.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — powinno być `MariaDB upgrade not required` i brak błędów `mysql.event`

## 10.3 → 10.4 (zweryfikowane lokalnie 2026-08-17, wynik: 10.4.34-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.3-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.3` → `mariadb:10.4`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.4.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — uwaga: od tej wersji obrazu entrypoint loguje
   `MariaDB upgrade ... required, but skipped due to $MARIADB_AUTO_UPGRADE setting`
   zamiast `upgrade not required` — to nie jest błąd, tylko inny komunikat entrypointu;
   liczy się brak błędów typu `mysql.event`/table-mismatch

## 10.4 → 10.5 (zweryfikowane lokalnie 2026-08-17, wynik: 10.5.29-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.4-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.4` → `mariadb:10.5`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
   (tabele `.frm` dostają "Auto_increment checked and .frm file version updated" —
   normalne przy tym skoku)
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.5.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów

**Ważne dla produkcji:** ten hop konsoliduje tabele uprawnień — `mysql.user` przestaje
być samodzielnym źródłem prawdy, dochodzi `mysql.global_priv`. Jeśli którakolwiek apka
odpytuje bezpośrednio `mysql.user` (poza standardowym `GRANT`/`SHOW GRANTS`), sprawdzić
przed upgrade'em na produkcji, czy nadal działa zgodnie z oczekiwaniami.

## 10.5 → 10.6 (zweryfikowane lokalnie 2026-08-17, wynik: 10.6.28-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.5-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.5` → `mariadb:10.6`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
   (przy starcie pojawił się ponownie błąd `mysql.event`/Event Scheduler disabled —
   normalne po majorowym skoku, ten krok to naprawia)
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.6.x, `SHOW DATABASES;` — doszła nowa baza systemowa
   `sys` (diagnostyka/monitoring), reszta zgodna z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów tabel (ostrzeżenia o `io_uring`/`liburing` i `expire-logs-days` bez
   `log-bin` są nieszkodliwe, środowiskowe/konfiguracyjne, nie blokują startu)

## 10.6 → 10.7 (zweryfikowane lokalnie 2026-08-17, wynik: 10.7.8-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.6-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.6` → `mariadb:10.7`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.7.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów, `MariaDB upgrade not required`

## 10.7 → 10.8 (zweryfikowane lokalnie 2026-08-17, wynik: 10.8.8-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.7-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.7` → `mariadb:10.8`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.8.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów, `MariaDB upgrade not required`

**Uwaga:** 10.8 nie jest wersją LTS (LTS to 10.6 i 10.11) — na produkcji warto
rozważyć docelowe zatrzymanie się na najbliższym LTS (10.11) zamiast przechodzenia
przez każdą krótkoterminową wersję pośrednią.

## 10.8 → 10.9 (zweryfikowane lokalnie 2026-08-17, wynik: 10.9.8-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.8-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.8` → `mariadb:10.9`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.9.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów

Wykonane automatycznie skryptem `upgrade.sh` (patrz sekcja "Automatyzacja" niżej).

## 10.9 → 10.10 (zweryfikowane lokalnie 2026-08-17, wynik: 10.10.7-MariaDB)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.9-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.9` → `mariadb:10.10`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.10.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów, `MariaDB upgrade not required`

Wykonane automatycznie skryptem `upgrade.sh`.

## 10.10 → 10.11 (zweryfikowane lokalnie 2026-08-17, wynik: 10.11.18-MariaDB, LTS)

1. (produkcja) Backup datadir przed zmianą, np.
   `cp -a ./database ./database.bak-10.10-<data>` lub mysqldump/xtrabackup.
2. `docker-compose.yml`: `image: mariadb:10.10` → `mariadb:10.11`
3. `docker compose pull db && docker compose up -d db`
4. `docker compose exec db mysql_upgrade -u root -p`
5. Weryfikacja:
   `docker compose exec db mysql -u root -p -e "SELECT VERSION(); SHOW DATABASES;"`
   → `SELECT VERSION();` → 10.11.x, `SHOW DATABASES;` zgodne z listą sprzed upgrade'u
6. Restart kontenera i sprawdzenie logów:
   `docker compose restart db && docker logs mariadb --tail 30`
   — brak błędów; nowy nieszkodliwy warning od tej wersji:
   `/sys/fs/cgroup///memory.pressure not writable, functionality unavailable to MariaDB`
   (środowiskowy, związany z cgroup na hoście, nie blokuje startu)

Wykonane automatycznie skryptem `upgrade.sh`. **10.11 to seria LTS — dobry punkt
zatrzymania na produkcji**, jeśli nie ma potrzeby iść dalej.

## Automatyzacja: `upgrade.sh`

Skrypt `upgrade.sh` w tym katalogu automatyzuje sekwencję hopów opisanych wyżej
(zmiana tagu obrazu, pull, up, streaming logów startowych, mysql_upgrade, weryfikacja,
restart + sprawdzenie logów) z potwierdzeniem z CLI przed każdym hopem i przy każdym
wykrytym problemie. Zaprojektowany do użycia zarówno lokalnie, jak i na produkcji
(ten sam mechanizm docker compose).

Użycie:
```
./upgrade.sh --from 10.1 --to 10.11              # pełny łańcuch, z backupem datadira
./upgrade.sh --from 10.8 --to 10.11 --skip-backup # bez backupu (np. lokalnie, brak miejsca)
./upgrade.sh --from 10.8 --to 10.11 --yes         # bez promptów potwierdzenia
```

Wymaga zgodności `--from` z aktualnym tagiem obrazu w `docker-compose.yml` (kontrola
przed startem, żeby nie zacząć od złego miejsca w łańcuchu). Pyta o hasło roota raz
na start (trzymane tylko w pamięci procesu). **Nie dopisuje automatycznie do tego
README** — wpisy dla każdego hopu trzeba dodać ręcznie po zakończeniu przebiegu,
zachowując format powyżej.
