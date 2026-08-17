# Quickstart: weryfikacja fundamentu API

**Feature**: 006-labsample-api-foundation | **Date**: 2026-08-15

Scenariusze weryfikacji dla każdej historii użytkownika. Uruchamiać po zakończeniu odpowiedniej
fazy z `tasks.md`.

> Zadania T041 i T052 uzupełniają ten dokument o ustalenia z implementacji — sekcje oznaczone
> „*(do uzupełnienia w T0xx)*" są celowo niepełne na tym etapie.

---

## Warunki wstępne

```bash
cd /home/pswider/rails/api_masdiag
rvm use 3.1.2
bundle install                    # po T001 (gem audited)
bin/rails db:migrate RAILS_ENV=test
```

⚠️ Migracje bazy `LabSample` wymagają zgody użytkownika (T004, T012, T030, T031, T044).

---

## US2 — Logowanie pracownika

**Cel**: pracownik loguje się dotychczasowym hasłem, w obu formatach.

### Testy automatyczne

```bash
bundle exec rspec spec/services/lab_sample/authenticator_spec.rb
bundle exec rspec spec/requests/lab_sample/sessions_spec.rb
bundle exec rspec spec/models/user_spec.rb
```

### Weryfikacja ręczna

| # | Scenariusz | Oczekiwane |
|---|---|---|
| 1 | Logowanie kontem z `labpanel` (ma `encrypted_password`) | 200 + token |
| 2 | Logowanie kontem wyłącznie desktopowym (ma `Password`/`Salt`) | 200 + token |
| 3 | Konto z oboma formatami | 200 + token; użyty bcrypt |
| 4 | Logowanie adresem e-mail zamiast loginu | 200 + token |
| 5 | Błędne hasło | 401, komunikat identyczny jak w #6 i #7 |
| 6 | Nieistniejący login | 401, komunikat identyczny jak w #5 |
| 7 | Konto nieaktywne (`IsActive = false`) | 401, komunikat identyczny jak w #5 |
| 8 | `DELETE /lab_sample/sessions/current` | 204; token przestaje działać |

```bash
# Scenariusz 1–4
curl -s -X POST http://localhost:3000/lab_sample/sessions \
  -H 'Content-Type: application/json' \
  -d '{"login":"<login lub email>","password":"<hasło>"}'
```

**Kryterium SC-002**: żaden pracownik nie musiał zmienić hasła.
**Kryterium SC-002a**: pracownik z kontem w `labpanel` używa **tego samego hasła** co w panelu.

**Kontrola bezpieczeństwa**: czasy odpowiedzi dla scenariuszy 5–7 nie mogą się istotnie różnić
(atrapa weryfikacji z T018a) — inaczej można zdalnie ustalić, które konta istnieją.

*(zakres do uzupełnienia w T052 — rzeczywiste loginy testowe i zmierzone czasy)*

---

## US1 — Ochrona przed cichym nadpisaniem

**Cel**: konflikt edycji jest wykrywany, także gdy druga zmiana pochodzi z aplikacji desktopowej.

### Testy automatyczne

```bash
bundle exec rspec spec/models/project_spec.rb
bundle exec rspec spec/requests/lab_sample/concurrency_spec.rb
```

### Weryfikacja ręczna

| # | Scenariusz | Oczekiwane |
|---|---|---|
| 1 | Dwa zapisy z tym samym `lock_version` | pierwszy 200, drugi **409** `stale_record` |
| 2 | Zapis po odświeżeniu danych | 200 |
| 3 | **Zmiana przez `UPDATE` SQL, potem zapis przez API** | **409** — sedno FR-003 |
| 4 | Rekord sprzed migracji (domyślny `lock_version`, znacznik nieustawiony) | zapis się udaje (FR-004) |
| 5 | Edycja tego samego projektu w starej aplikacji i w API | konflikt wykryty |

```bash
# Scenariusz 3 — symulacja zapisu z Entity Framework (pomija lock_version)
mysql LabSample -e "UPDATE Projects SET Name = 'zmiana z EF' WHERE Id = <id>;"
# następnie PATCH przez API z poprzednim lock_version → oczekiwane 409
```

**Kryterium SC-001**: liczba cichych utrat zmian = **zero**.

*(nazwa kolumny znacznika do uzupełnienia po rozstrzygnięciu T025)*

---

## US3 — Ślad audytowy

**Cel**: każda zmiana przez API wskazuje konkretnego pracownika.

### Testy automatyczne

```bash
bundle exec rspec spec/models/audit_spec.rb
bundle exec rspec spec/requests/lab_sample/audit_spec.rb
```

### Weryfikacja ręczna

| # | Scenariusz | Oczekiwane |
|---|---|---|
| 1 | Zmiana rekordu przez API | wpis w `audits` z `user_type`/`user_id` zalogowanego pracownika |
| 2 | Kilka kolejnych zmian tego samego rekordu | rosnące `version`, odtwarzalna kolejność (FR-013) |
| 3 | Zmiany dwóch różnych pracowników pod rząd | każdy wpis wskazuje właściwą osobę |
| 4 | Zmiana przez konto partnerskie (`ApiAccount`) | wpis rozpoznaje typ autora |

```sql
SELECT id, auditable_type, auditable_id, user_type, user_id, action, version, created_at
FROM audits
WHERE auditable_type = 'Project' AND auditable_id = <id>
ORDER BY version;
```

**Kryterium SC-003/SC-004**: „kto zmienił ten rekord" to jedno zapytanie.

### ⚠️ Ograniczenie zakresu audytu — do zakomunikowania użytkownikom

`audited` rejestruje wyłącznie zapisy przechodzące przez ActiveRecord. **Zapisy z aplikacji
desktopowej (Entity Framework) nie zostawiają śladu.** Audyt jest kompletny tylko dla modułów
już przeniesionych do API — w okresie przejściowym obraz jest częściowy i rośnie wraz
z kolejnymi modułami.

*(pełne brzmienie komunikatu do uzupełnienia w T041)*

---

## US4 — Sesje polimorficzne

**Cel**: jedna tabela sesji dla kontraktorów (toxo) i pracowników, bez regresji.

### Regresja — obowiązkowa

```bash
# PRZED zmianą (T042) — zapisać wynik
bundle exec rspec spec/requests/toxo/ > /tmp/toxo-before.txt

# PO zmianie (T047)
bundle exec rspec spec/requests/toxo/ > /tmp/toxo-after.txt
diff /tmp/toxo-before.txt /tmp/toxo-after.txt
```

**Kryterium SC-005**: zero regresji. Jakakolwiek różnica w liczbie przechodzących testów
wstrzymuje wdrożenie.

| # | Scenariusz | Oczekiwane |
|---|---|---|
| 1 | Istniejąca sesja toxo po migracji | działa bez zmian |
| 2 | `owner_type`/`owner_id` po backfillu | `"Contractor"` + dawne `contractor_id` |
| 3 | Sesja pracownika i sesja kontraktora obok siebie | obie działają |

---

## Weryfikacja końcowa (Phase 7)

```bash
bundle exec rspec                      # T050 — pełna regresja
```

Sprawdzić brak regresji we **wszystkich** namespace'ach: `v1`, `fv1`, `nume`, `lalen`,
`masdiag`, `masdiag_mailer`, `regspec`, `patient_portal`, `webhook`, `toxo`.

**Kontrola sekretów (T051)** — `Password`, `Salt`, `encrypted_password` ani token nie mogą
pojawić się w logach ani w odpowiedziach API:

```bash
grep -riE "password|salt|token" log/test.log | grep -v "FILTERED" | head
```

---

## Rollback

Praca na gałęzi `labsample3`. Migracje bazy współdzielonej wycofywać **wyłącznie** po
potwierdzeniu, że żadna inna aplikacja nie zaczęła korzystać z nowych kolumn:

```bash
bin/rails db:rollback STEP=<n>
```

`sessions.contractor_id` jest celowo zachowana po migracji US4 — umożliwia powrót bez utraty
danych. Usunąć dopiero po okresie obserwacji.
