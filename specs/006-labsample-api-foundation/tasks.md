---
description: "Task list for LabSample API Foundation (concurrency, employee auth, audit)"
---

# Tasks: Fundament API dla aplikacji laboratoryjnej

**Input**: Design documents from `/specs/006-labsample-api-foundation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: REQUIRED. Konstytucja III (Test-First, NON-NEGOTIABLE) wymaga specyfikacji RSpec
napisanych i **failujących** przed implementacją. Wyłącznie FactoryBot, bez fixtures.

**Organization**: Zadania pogrupowane wg historii użytkownika ze `spec.md`, w kolejności priorytetów.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: może iść równolegle (inne pliki, brak zależności od niezakończonych zadań)
- **[Story]**: US1–US4 wg `spec.md`
- Ścieżki plików są względne do `/home/pswider/rails/api_masdiag`

## Mapa historii

| Story | Cel | Priorytet | Zależy od |
|---|---|---|---|
| US1 | Ochrona przed cichym nadpisaniem | P1 | Foundational |
| US2 | Logowanie pracownika (dwa formaty haseł) | P1 | Foundational |
| US3 | Ślad audytowy | P2 | US2 |
| US4 | Wspólny mechanizm dostępu (sesje polimorficzne) | P3 | US2 |

**MVP**: US1 + US2 (obie P1, wzajemnie niezależne).

---

## ⚠️ Bramki wymagające zgody użytkownika

Baza `LabSample` jest współdzielona przez 9 aplikacji. Zgodnie z `CLAUDE.md` **każda migracja
wymaga jawnego potwierdzenia przed uruchomieniem**. Zadania **T004, T012, T030, T031, T044**
są blokujące — nie uruchamiać `db:migrate` bez zgody.

Dodatkowo **T025 jest bramką decyzyjną** (nie migracją): bez rozstrzygnięcia kształtu i nazwy
znacznika nie można wykonać T025a, T031 ani T033.

---

## Phase 1: Setup

**Purpose**: Zależności i szkielet namespace'u.

- [ ] T001 Dodać `gem "audited", "~> 5.8"` do `Gemfile` i uruchomić `bundle install` (tabela `audits` **już istnieje** w bazie — nie generować migracji, patrz research.md R3)
- [ ] T002 [P] Utworzyć katalogi `app/controllers/lab_sample/`, `app/services/lab_sample/`, `app/resources/lab_sample/`, `app/policies/lab_sample/`
- [ ] T003 [P] Utworzyć katalogi testów `spec/requests/lab_sample/`, `spec/services/lab_sample/`

---

## Phase 2: Foundational (blokuje wszystkie historie)

**Purpose**: Tożsamość autora — wymagana zarówno przez audyt (US3), jak i przez powiązanie sesji.

⚠️ **T004 wymaga zgody użytkownika (zmiana schematu).**

- [ ] T004 Utworzyć migrację `db/migrate/*_create_people.rb` — tabela `people`: `personable_type` (string, NOT NULL), `personable_id` (bigint, NOT NULL), timestamps, unikalny indeks `[personable_type, personable_id]`. **Nie uruchamiać bez zgody**
- [ ] T005 [P] Napisać failujący spec `spec/models/person_spec.rb` — walidacja unikalności `personable_id` w zakresie `personable_type`, polimorficzne powiązanie, `fullname` delegowane do właściciela
- [ ] T006 [P] Napisać failujący spec `spec/models/concerns/personable_spec.rb` — automatyczne tworzenie `Person` przy nowym rekordzie
- [ ] T007 [P] Utworzyć fabrykę `spec/factories/people.rb`
- [ ] T008 Zaimplementować `app/models/person.rb` — `audited`, `belongs_to :personable, polymorphic: true`, walidacja unikalności, `fullname` (wzorzec: `masdiag_com/app/models/person.rb`, ale MySQL/bigint zamiast UUID)
- [ ] T009 Zaimplementować `app/models/concerns/personable.rb` — `has_one :person, as: :personable, required: true`, `before_validation :prep_person`
- [ ] T010 [P] Dodać `include Personable` do `app/models/user.rb`
- [ ] T011 [P] Dodać `include Personable` do `app/models/api_account.rb` — zweryfikować **brak regresji** dla wszystkich istniejących namespace'ów (FR-008)
- [ ] T012 Utworzyć migrację danych `db/migrate/*_backfill_people.rb` — utworzyć `Person` dla istniejących rekordów `Users` i `ApiAccounts`; bez tego `required: true` odrzuci pierwszy zapis istniejącego konta (research.md R4). **Nie uruchamiać bez zgody**

**Checkpoint**: `Person` działa; każde konto ma tożsamość.

---

## Phase 3: US2 — Logowanie pracownika (P1) 🥇

**Goal**: Pracownik loguje się dotychczasowym hasłem — **z panelu webowego albo z aplikacji
desktopowej** — i otrzymuje token.

**Independent Test**: Zalogowanie kontem z `labpanel` (bcrypt) oraz kontem wyłącznie desktopowym
(PBKDF2) zwraca token; żadne hasło nie zostało zmienione.

**Kontekst**: tabela `Users` zawiera dwa równoległe systemy uwierzytelniania — `Login`/`Password`/`Salt`
(PBKDF2, LabSample C#) oraz `email`/`encrypted_password` (bcrypt/Devise, `labpanel`). API akceptuje
oba, z pierwszeństwem bcrypt. Pełne ujednolicenie po wygaszeniu aplikacji desktopowej
(research.md R1b).

### Testy (RED)

- [ ] T013 [P] [US2] Napisać failujący spec `spec/services/lab_sample/authenticator_spec.rb` — **oba formaty hasła**: konto z `encrypted_password` (bcrypt, jak w `labpanel`), konto tylko z `Password`/`Salt` (PBKDF2), konto z oboma (bcrypt ma pierwszeństwo), błędne hasło, konto nieaktywne, nieistniejący login
- [ ] T014 [P] [US2] Utworzyć fabrykę `spec/factories/users.rb` z trzema wariantami (traits): `:with_bcrypt_password` (`encrypted_password` przez `BCrypt::Password.create`), `:with_pbkdf2_password` (`Password`/`Salt` algorytmem z `PasswordHasher.cs`), `:with_both`
- [ ] T015 [P] [US2] Napisać failujący spec `spec/requests/lab_sample/sessions_spec.rb` — `POST /lab_sample/sessions` (200 + token), błędne dane (401), konto nieaktywne (401), logowanie **loginem oraz adresem e-mail**, `DELETE /lab_sample/sessions/current` (204), token po wylogowaniu (401)
- [ ] T016 [P] [US2] Napisać failujący spec `spec/models/user_spec.rb` — weryfikacja hasła w obu formatach i `active?`

### Implementacja (GREEN)

- [ ] T017 [US2] Zaimplementować `app/services/lab_sample/authenticator.rb` — `< ApplicationService`, kontrakt `success?`/`payload`/`error`; **weryfikacja dwuformatowa**: `encrypted_password` niepuste → `BCrypt::Password.new(...) == password`, w przeciwnym razie PBKDF2-HMAC-SHA1 10 000 iteracji/64 B/base64 z `secure_compare` (research.md R1, R1b). **Nie dodawać gemu Devise** — `bcrypt` jest już w `Gemfile:51`
- [ ] T018 [US2] Dodać do `app/models/user.rb` metody `authenticate(password)`, `active?` oraz wyszukiwanie po `Login` **lub** `email` (delegacja do serwisu; model bez logiki biznesowej — konstytucja II)
- [ ] T018a [P] [US2] Dodać do `LabSample::Authenticator` atrapę weryfikacji dla nieistniejącego loginu — stały czas odpowiedzi niezależnie od tego, czy konto istnieje i którym formatem dysponuje (ochrona przed atakiem czasowym)
- [ ] T019 [US2] Dodać `attribute :lab_user` do `app/models/current.rb`
- [ ] T020 [US2] Zaimplementować `app/controllers/lab_sample/base_controller.rb` — dziedziczy **wprost z `ActionController::API`**; `authenticate_lab_user!` (Bearer), `current_lab_user`, `alias_method :pundit_user`, `rescue_from` dla Pundit/StaleObject/RecordNotFound/RecordInvalid, ustawianie i **czyszczenie** `Current.lab_user`
- [ ] T021 [US2] Zaimplementować `app/controllers/lab_sample/sessions_controller.rb` — `create` (logowanie), `destroy` (wylogowanie); akcja ≤ 15 linii (konstytucja VI)
- [ ] T022 [P] [US2] Zaimplementować `app/resources/lab_sample/session_resource.rb` (Alba) — token + dane pracownika, **bez** `Password` i `Salt` (konstytucja IV)
- [ ] T023 [US2] Dodać trasy `namespace :lab_sample` w `config/routes.rb` — `resource :sessions, only: %i[create]` + `delete "sessions/current"`
- [ ] T024 [US2] Dodać filtrowanie parametru `password` w `config/initializers/filter_parameter_logging.rb` (konstytucja IV — sekrety nie trafiają do logów)

**Checkpoint**: US2 działa niezależnie — pracownik uzyskuje token dotychczasowym hasłem.

---

## Phase 4: US1 — Ochrona przed cichym nadpisaniem (P1) 🥇

**Goal**: Konflikt edycji jest wykrywany, także gdy druga zmiana pochodzi ze starej aplikacji.

**Independent Test**: Dwa zapisy tego samego rekordu — drugi odrzucony z `409`.

⚠️ **T031 wymaga zgody użytkownika (zmiana schematu).**

### Decyzja projektowa (przed implementacją)

- [ ] T025 [US1] **BRAMKA DECYZYJNA — blokuje T031, T033 i całą fazę US1.** Rozstrzygnąć z użytkownikiem kształt znacznika bazodanowego: `ON UPDATE CURRENT_TIMESTAMP` nałożony na istniejącą kolumnę `updated_at` w `Projects` **czy** nowa kolumna techniczna. Kontekst: encja C# `Project` nie zna ani `updated_at`, ani `lock_version`, więc tylko mechanizm bazodanowy wykryje zapis z EF (research.md R2).
  **Kryteria rozstrzygnięcia** (wszystkie trzy muszą być spełnione, zanim ruszy T026):
  1. wybrany wariant (istniejąca kolumna vs nowa) wraz z uzasadnieniem wpływu na 9 aplikacji współdzielących bazę;
  2. **nazwa kanoniczna kolumny** — jedna, obowiązująca we wszystkich dokumentach;
  3. nazwa pola w API (dziś kontrakt używa `updated_marker`) — ta sama albo świadomie inna, jeśli nazwa kolumny nie ma wyciekać na zewnątrz
- [ ] T025a [US1] Po rozstrzygnięciu T025 ujednolicić nazewnictwo znacznika w trzech plikach: `specs/006-labsample-api-foundation/contracts/auth-endpoints.md` (dziś `updated_marker`), `specs/006-labsample-api-foundation/data-model.md` (dziś opisowo „znacznik") oraz `specs/006-labsample-api-foundation/quickstart.md` (sekcja US1) — usunąć rozbieżność terminologiczną przed implementacją

### Testy (RED)

- [ ] T026 [P] [US1] Napisać failujący spec `spec/models/project_spec.rb` — optimistic locking podnosi `lock_version`; zapis z nieaktualną wersją rzuca `ActiveRecord::StaleObjectError`
- [ ] T027 [P] [US1] Napisać failujący spec `spec/requests/lab_sample/concurrency_spec.rb` — dwa kolejne zapisy z tym samym `lock_version` → drugi zwraca `409` z kodem `stale_record`
- [ ] T028 [P] [US1] Napisać failujący spec symulujący zapis ze starej aplikacji — bezpośredni `UPDATE` SQL pomijający `lock_version`, następnie zapis przez API → `409` (weryfikuje FR-003, czyli sedno US1)
- [ ] T029 [P] [US1] Napisać failujący spec — rekord sprzed migracji (`lock_version` domyślne) pozostaje zapisywalny (FR-004)

### Implementacja (GREEN)

- [ ] T030 [US1] Napisać migrację `db/migrate/*_add_lock_version_to_projects.rb` — `lock_version` integer, default 0, NOT NULL. **Nie uruchamiać bez zgody**
- [ ] T031 [US1] Napisać migrację znacznika bazodanowego wg decyzji z T025 (`ON UPDATE CURRENT_TIMESTAMP`). **Nie uruchamiać bez zgody**
- [ ] T032 [US1] Dodać `self.locking_column = "lock_version"` do `app/models/project.rb`
- [ ] T033 [US1] Zaimplementować `app/services/lab_sample/stale_record_check.rb` — `< ApplicationService`, kontrakt `success?`/`payload`/`error`; porównuje przesłany znacznik (nazwa wg T025) z bieżącą wartością w bazie przed zapisem, niezgodność → wynik błędu przechwytywany przez `render_conflict`. To sygnał wykrywający zapis z Entity Framework, którego `lock_version` nie wychwyci (research.md R2)
- [ ] T034 [US1] Dodać `render_conflict` w `LabSample::BaseController` — `409` z kopertą `{ error: { code: "stale_record", ... } }` wg `contracts/auth-endpoints.md`

**Checkpoint**: US1 działa — konflikty wykrywane w obu kierunkach (API↔API i EF↔API).

---

## Phase 5: US3 — Ślad audytowy (P2)

**Goal**: Każda zmiana przez API zostawia ślad wskazujący konkretnego pracownika.

**Independent Test**: Zmiana rekordu przez API tworzy wpis w `audits` z tożsamością autora,
a seria zmian pozwala odtworzyć kolejność i kolejne stany rekordu (FR-013).

**Zależy od**: US2 (bez rozpoznania pracownika nie ma czego zapisać).

### Testy (RED)

- [ ] T035 [P] [US3] Napisać failujący spec `spec/models/audit_spec.rb` — zmiana rekordu tworzy wpis z `user_type`/`user_id`, `audited_changes` i rosnącym `version`
- [ ] T035a [P] [US3] Napisać failujący spec `spec/models/audit_history_spec.rb` — **odtwarzalność kolejności zmian (FR-013)**: po serii zmian tego samego rekordu `audits` uporządkowane po `version` odtwarzają kolejne stany rekordu; `version` jest ciągłe i rosnące, a `audited_changes` każdego wpisu wskazuje wartość przed i po
- [ ] T036 [P] [US3] Napisać failujący spec `spec/requests/lab_sample/audit_spec.rb` — zmiana przez API wskazuje zalogowanego pracownika jako autora
- [ ] T037 [P] [US3] Napisać failujący spec izolacji — dwa kolejne żądania od różnych pracowników nie mieszają autorów (`Audited.store` jest wątkowy)

### Implementacja (GREEN)

- [ ] T038 [US3] Dodać `config/initializers/audited.rb` — konfiguracja `audited_user` i `current_user_method`
- [ ] T039 [US3] Dodać `audited` do `app/models/project.rb`
- [ ] T040 [US3] Ustawiać autora audytu w `LabSample::BaseController` (`around_action`) — z **gwarantowanym czyszczeniem** po żądaniu (`ensure`), żeby nie przypisać zmiany niewłaściwej osobie
- [ ] T041 [P] [US3] Uzupełnić sekcję „Ograniczenie zakresu audytu" w `specs/006-labsample-api-foundation/quickstart.md` o pełne brzmienie komunikatu dla użytkowników — zapisy ze starej aplikacji (EF) **nie** trafiają do audytu; ślad jest kompletny tylko dla modułów przeniesionych do API

**Checkpoint**: US3 działa — audyt odpowiada na pytanie „kto zmienił ten rekord".

---

## Phase 6: US4 — Sesje polimorficzne (P3)

**Goal**: Jedna tabela sesji obsługuje kontraktorów (toxo) i pracowników (LabSample).

**Independent Test**: Istniejący klient toxo działa bez zmian, a sesje pracowników korzystają
z tego samego mechanizmu.

⚠️ **Największe ryzyko regresji w całej funkcji** — dotyka działającego klienta produkcyjnego.
⚠️ **T044 wymaga zgody użytkownika (zmiana schematu).**

### Testy (RED)

- [ ] T042 [US4] Uruchomić `bundle exec rspec spec/requests/toxo/` i **zapisać wynik jako punkt odniesienia** przed jakąkolwiek zmianą
- [ ] T043 [P] [US4] Napisać failujący spec `spec/models/session_spec.rb` — polimorficzny `owner`; sesja `Contractor` i sesja `User` współistnieją

### Implementacja (GREEN)

- [ ] T044 [US4] Napisać migrację `db/migrate/*_make_sessions_polymorphic.rb` — dodać `owner_type`/`owner_id`, backfill (`owner_type = "Contractor"`, `owner_id = contractor_id`), indeks `[owner_type, owner_id]`; **`contractor_id` zostawić** (możliwość wycofania). **Nie uruchamiać bez zgody**
- [ ] T045 [US4] Zmienić `app/models/session.rb` na `belongs_to :owner, polymorphic: true`
- [ ] T046 [US4] Dostosować `app/controllers/toxo/base_controller.rb` — `current_contractor` przez `@current_session.owner`, zachowując dotychczasowe zachowanie
- [ ] T047 [US4] Uruchomić `bundle exec rspec spec/requests/toxo/` i porównać z punktem odniesienia z T042 — **zero regresji** (SC-005)
- [ ] T048 [US4] Przełączyć `LabSample::SessionsController` na tworzenie sesji z `owner` = pracownik

**Checkpoint**: US4 działa — wspólny mechanizm, toxo bez regresji.

---

## Phase 7: Domknięcie

- [ ] T049 [P] Napisać `app/policies/lab_sample/application_policy.rb` wraz ze specem — baza dla polityk kolejnych modułów
- [ ] T050 [P] Uruchomić pełne `bundle exec rspec` — weryfikacja braku regresji we **wszystkich** namespace'ach (v1, fv1, nume, lalen, masdiag, regspec, patient_portal, webhook, toxo)
- [ ] T051 [P] Zweryfikować, że `Password`, `Salt` ani token nie pojawiają się w logach ani w odpowiedziach API (konstytucja IV)
- [ ] T052 [P] Uzupełnić sekcję US2 w `specs/006-labsample-api-foundation/quickstart.md` o rzeczywiste loginy testowe (konto z `labpanel` — bcrypt; konto wyłącznie desktopowe — PBKDF2) oraz zmierzone czasy odpowiedzi dla scenariuszy 5–7, potwierdzające brak wycieku informacji o istnieniu konta
- [ ] T053 Zaktualizować `CLAUDE.md` — opis namespace'u `lab_sample` w sekcji API Namespaces oraz informacja o dwóch formatach haseł w tabeli `Users`
- [ ] T054 [P] Zapisać w `specs/006-labsample-api-foundation/research.md` warunki wejścia w fazę 2 ujednolicenia haseł (transparentna migracja PBKDF2 → bcrypt przy logowaniu, wyzerowanie `Password`/`Salt`, ujednolicenie `stretches` z labpanel) — **do realizacji jako osobna funkcja po wygaszeniu aplikacji desktopowej**, nie tutaj

---

## Zależności

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational: Person) ────┐
    ↓                              │
Phase 3 (US2 Logowanie) ◄──────────┤
    ↓         ↓                    │
Phase 5    Phase 6            Phase 4 (US1 Współbieżność)
(US3)      (US4)              — niezależna od US2
    ↓         ↓                    ↓
         Phase 7 (Domknięcie)
```

- **US1 i US2 są wzajemnie niezależne** — mogą powstawać równolegle po Phase 2
- **US3 wymaga US2** (autor audytu = zalogowany pracownik)
- **US4 wymaga US2** i jest celowo ostatnia (ryzyko regresji toxo)

## Możliwości zrównoleglenia

**Phase 2**: T005, T006, T007 równolegle (różne pliki); potem T010, T011 równolegle
**Phase 3**: T013–T016 równolegle (wszystkie to specy w różnych plikach)
**Phase 4**: T026–T029 równolegle
**Phase 5**: T035–T037 równolegle
**Phase 7**: T049–T052 równolegle

Przy dwóch osobach: jedna prowadzi US2 (Phase 3), druga US1 (Phase 4) — po zakończeniu Phase 2.

## Strategia wdrożenia

1. **MVP** = Phase 1 + 2 + 3 (US2) + 4 (US1). Po nim można rozpocząć pierwszy moduł nowej
   aplikacji (Projekty) — pracownik się loguje, a jego zapisy nie nadpiszą cudzej pracy.
2. **US3** dokłada audyt — właściwy cel biznesowy całego przedsięwzięcia.
3. **US4** porządkuje mechanizm sesji; wykonać jako ostatnie, z pełną regresją toxo.

Każda faza kończy się checkpointem — stanem, w którym system działa i można się zatrzymać.
