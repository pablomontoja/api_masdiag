# Implementation Plan: Fundament API dla aplikacji laboratoryjnej

**Branch**: `labsample3` | **Date**: 2026-08-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-labsample-api-foundation/spec.md`

## Summary

Fundament umożliwiający powstanie pierwszego modułu nowej aplikacji laboratoryjnej (LabSample3):
optymistyczna kontrola współbieżności, uwierzytelnianie pracownika laboratorium tokenem Bearer
(bez resetu haseł), audyt zmian przez gem `audited` oraz polimorficzne sesje wspólne dla toxo
i LabSample.

Kluczowe ustalenia ze stanu repozytorium:
- **tabela `audits` już istnieje** (`db/schema.rb:512`) z kompletnym układem kolumn gemu `audited`,
  ale gem nie jest zainstalowany i nic jej nie używa → aktywacja, nie budowa od zera;
- tabela `people` **nie istnieje** → do utworzenia;
- `sessions` ma `contractor_id NOT NULL` → migracja na polimorficzne `owner_type`/`owner_id`;
- `Projects` nie ma `lock_version` → do dodania dla pierwszego modułu.

## Technical Context

**Language/Version**: Ruby 3.3.7, Rails 7.1.5

**Primary Dependencies**: istniejące — `pundit`, `alba`, `pagy` (~> 6.2), `bcrypt` (~> 3.1.7),
`mysql2`; **do dodania** — `audited` (~> 5.8, zgodnie z wersją używaną w `masdiag_com`)

**Storage**: MySQL, baza `LabSample` — współdzielona z aplikacją desktopową i pozostałymi
aplikacjami Rails. Tabele C#-owe (`Users`, `Projects`) mają PascalCase i `Id` jako klucz główny

**Testing**: RSpec + FactoryBot + Shoulda. Konstytucja III (Test-First) jest **NON-NEGOTIABLE** —
specyfikacje piszemy przed implementacją (RED→GREEN), wyłącznie FactoryBot, bez fixtures.
Typy testów per warstwa: modele → unit, serwisy → unit, kontrolery → request, polityki → unit

**Target Platform**: API-only Rails (`ActionController::API`)

**Project Type**: API backend (istniejąca aplikacja, nowy namespace)

**Performance Goals**: nie dotyczy — fundament bez ścieżek krytycznych wydajnościowo

**Constraints**:
- baza współdzielona → **zmiany schematu wymagają potwierdzenia użytkownika** (zasada z `CLAUDE.md`)
- stara aplikacja pisze do tych samych tabel przez EF, omijając walidacje i callbacki Railsów
- zero regresji dla istniejących klientów (v1, fv1, nume, lalen, masdiag, toxo, regspec, webhook)
- hasła w `Users` muszą działać bez resetu

**Scale/Scope**: 1 nowy namespace, ~4 modele/migracje, 1 kontroler bazowy, ~2 endpointy
uwierzytelniania; brak modułów funkcjonalnych

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Oceniane wobec `.specify/memory/constitution.md` **v1.1.0** (zasady I–VI).

| Zasada | Status | Uzasadnienie |
|---|---|---|
| **I. Rails Conventions** | ✅ Zgodne | Nowy namespace `lab_sample` zachowuje separację per typ klienta; nazewnictwo Zeitwerk |
| **II. Service-Object Architecture** | ✅ Zgodne | Uwierzytelnianie w `LabSample::Authenticator < ApplicationService` z kontraktem `success?`/`payload`/`error`; kontroler tylko HTTP |
| **III. Test-First (NON-NEGOTIABLE)** | ✅ Zgodne | **Zadania ułożone RED→GREEN**: spec przed implementacją dla każdego modelu, serwisu, kontrolera i polityki; wyłącznie FactoryBot |
| **IV. Security & Secrets** | ⚠️ **Odstępstwo** | Konstytucja mówi „every request authenticates via HTTP Basic against `ApiAccount`" — ta funkcja wprowadza Bearer per pracownik. Uzasadnienie niżej |
| **V. Multi-Tenancy Integrity** | ✅ Zgodne | Nie narusza izolacji instytucji; `MasdiagCheck` i pozostałe concerny nietknięte |
| **VI. Layered Architecture** | ✅ Zgodne | Brak nowych katalogów; `Person`/`Personable` w `app/models/` + `concerns/`, polityki w `app/policies/lab_sample/` |
| Canonical Directory Structure | ✅ Zgodne | Wyłącznie podkatalogi w istniejących lokalizacjach |
| Zmiana schematu współdzielonej bazy (`CLAUDE.md`) | ⚠️ **Wymaga zgody** | 3 migracje: `people`, `sessions`, `Projects` |

**Wynik: PASS z dwoma udokumentowanymi odstępstwami** (szczegóły w Complexity Tracking):

1. **Bearer zamiast HTTP Basic** — zasada IV opisuje stan zastany, ale namespace `toxo` już dziś
   stosuje Bearer (`Toxo::BaseController`), więc precedens istnieje. HTTP Basic przeciwko
   `ApiAccount` **nie jest w stanie** zidentyfikować pracownika laboratorium (`ApiAccount`
   należy do `Contractor`), a bez tego nie ma audytu — czyli głównego celu funkcji.
   Wszystkie istniejące namespace'y zachowują HTTP Basic bez zmian (FR-008).

2. **Zmiany schematu bazy współdzielonej przez 9 aplikacji** — zgodnie z zasadą z `CLAUDE.md`
   **każda migracja wymaga jawnego potwierdzenia użytkownika przed uruchomieniem**; ujęte jako
   osobne zadania blokujące, nie jako założenie.

Ocena wpływu migracji na inne aplikacje:

| Migracja | Wpływ na istniejące aplikacje |
|---|---|
| `people` (nowa tabela) | Żaden — nikt jej nie używa |
| `sessions` → polimorficzne | **Dotyczy `toxo`** (jedyny konsument); wymaga backfillu i weryfikacji regresji |
| `Projects.lock_version` | Nowa kolumna z wartością domyślną; EF ją zignoruje (nie ma jej w modelu C#) |

## Project Structure

### Documentation (this feature)

```text
specs/006-labsample-api-foundation/
├── spec.md              # Specyfikacja (4 historie użytkownika)
├── plan.md              # Ten plik
├── research.md          # Phase 0 — decyzje techniczne
├── data-model.md        # Phase 1 — modele i migracje
├── quickstart.md        # Phase 1 — weryfikacja
├── contracts/
│   └── auth-endpoints.md
├── checklists/
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── lab_sample/
│       ├── base_controller.rb        # Bearer + Pundit + Current.lab_user + audyt
│       └── sessions_controller.rb    # logowanie / wylogowanie
├── models/
│   ├── person.rb                     # NOWY — polimorficzna tożsamość autora
│   ├── concerns/
│   │   └── personable.rb             # NOWY
│   ├── session.rb                    # ZMIANA — belongs_to :owner, polymorphic
│   ├── user.rb                       # ZMIANA — Personable + weryfikacja hasła
│   ├── api_account.rb                # ZMIANA — Personable
│   ├── project.rb                    # ZMIANA — audited + lock_version
│   └── current.rb                    # ZMIANA — atrybut lab_user
├── services/
│   └── lab_sample/
│       └── authenticator.rb          # NOWY — weryfikacja PBKDF2
├── resources/
│   └── lab_sample/
│       └── session_resource.rb       # NOWY — Alba
└── policies/
    └── lab_sample/                   # NOWY katalog

db/migrate/
├── *_create_people.rb                          # wymaga zgody
├── *_make_sessions_polymorphic.rb              # wymaga zgody
└── *_add_lock_version_to_projects.rb           # wymaga zgody

spec/
├── requests/lab_sample/
├── models/
└── factories/
```

**Structure Decision**: Nowy namespace `lab_sample` wzorowany **koncepcyjnie** na `toxo`
(`BaseController` dziedziczący wprost z `ActionController::API`, Bearer, Pundit), ale
**bez ponownego użycia** `app/controllers/concerns/toxo/*` — zgodnie z wcześniejszym ustaleniem,
że skala zmian wymaga dedykowanych rozwiązań. Pliki i katalogi w `snake_case` (`lab_sample/`),
moduł Ruby `LabSample` — wymóg Zeitwerk.

## Kluczowe decyzje techniczne

Pełne uzasadnienia w `research.md`. Skrót:

| # | Decyzja | Uzasadnienie |
|---|---|---|
| D1 | Weryfikacja hasła **dwuformatowa**: najpierw bcrypt (`encrypted_password`), w razie braku PBKDF2 (`Password`/`Salt`) | Tabela `Users` ma oba systemy; bcrypt używa `labpanel`, PBKDF2 — LabSample C#. Zero resetów dla obu grup |
| D1a | **Bez gemu Devise** w api_masdiag; weryfikacja bcrypt wprost przez `BCrypt::Password` | Devise obsługuje sesje przeglądarkowe; to API tokenowe. `bcrypt` jest już w Gemfile |
| D2 | Współbieżność: `lock_version` (ActiveRecord optimistic locking) | Wbudowane w Rails, czytelny wyjątek `StaleObjectError` |
| D2a | Dodatkowo kolumna znacznika z `ON UPDATE CURRENT_TIMESTAMP` (poziom bazy) | Jedyny sposób wykrycia zapisu ze starej aplikacji — patrz niżej |
| D3 | Audyt: gem `audited` ~> 5.8 | Tabela `audits` już istnieje z pasującym układem kolumn |
| D4 | Tożsamość autora: `Person` + `Personable` (wzorzec z `masdiag_com`) | Jednolity autor dla `User` i `ApiAccount` |
| D5 | Sesje polimorficzne z backfillem `owner_type = "Contractor"` | Wspólny mechanizm dla toxo i LabSample |
| D6 | Token: `SecureRandom.urlsafe_base64(32)`, jak w istniejącym `Session` | Spójność z toxo |

**Najważniejsze ryzyko techniczne (D2a) — zweryfikowane na kodzie C#:**

Encja `LabSample.Dal/Entities/Project.cs` ma **16 pól i nie zawiera ani `updated_at`, ani
`lock_version`**. Oznacza to, że zapis ze starej aplikacji:
- nie podniesie `lock_version` → optimistic locking Railsów go nie zauważy;
- nie zaktualizuje `updated_at` → porównanie znacznika w kodzie Ruby też go nie zauważy.

Sam mechanizm aplikacyjny **nie jest w stanie** spełnić FR-003 („wykrywanie musi działać również
wtedy, gdy zmiana pochodzi ze starej aplikacji").

**Rozwiązanie: przenieść wykrywanie na poziom bazy danych.** Kolumna znacznika zadeklarowana jako
`ON UPDATE CURRENT_TIMESTAMP` jest aktualizowana przez sam MySQL przy każdym `UPDATE` wiersza —
niezależnie od tego, czy piszący klient w ogóle wie o jej istnieniu. EF zaktualizuje ją
mimowolnie, po prostu zapisując rekord.

Kontrola opiera się więc na dwóch sygnałach o różnych rolach:

| Sygnał | Wykrywa | Mechanizm |
|---|---|---|
| `lock_version` | konflikt nowa ↔ nowa | ActiveRecord optimistic locking |
| znacznik `ON UPDATE CURRENT_TIMESTAMP` | konflikt **stara ↔ nowa** | MySQL, niezależnie od klienta |

Szczegóły i rozważone alternatywy (trigger, kolumna cieni, brak wykrywania) w `research.md` R2.

## Kolejność prac

1. **Fundament danych** — `people`, `Personable`, gem `audited` (nie wymaga zmian w `sessions`)
2. **US2 Logowanie** — serwis uwierzytelniania, `LabSample::BaseController`, `Current.lab_user`
3. **US1 Współbieżność** — `lock_version` + weryfikacja `updated_at`, obsługa konfliktu
4. **US3 Audyt** — `audited` na modelach, powiązanie autora z żądaniem
5. **US4 Sesje polimorficzne** — migracja + backfill + regresja toxo
6. **Domknięcie** — dokumentacja, przegląd regresji wszystkich namespace'ów

US1 i US2 są niezależne (można równolegle). US3 wymaga US2. US4 jest ostatnie, bo dotyka
działającego klienta (toxo) i niesie największe ryzyko regresji.

## Complexity Tracking

| Odstępstwo | Dlaczego konieczne | Odrzucona prostsza opcja |
|---|---|---|
| **Bearer zamiast HTTP Basic** (zasada IV) | `ApiAccount` należy do `Contractor`, więc HTTP Basic nie identyfikuje pracownika laboratorium — bez tego audyt (główny cel funkcji) jest niemożliwy. Precedens: `Toxo::BaseController` już stosuje Bearer | HTTP Basic przeciwko `ApiAccount` — nie spełnia FR-007 ani US3 |
| Podwójna kontrola współbieżności (`lock_version` + znacznik `ON UPDATE`) | Zweryfikowano na kodzie: encja C# `Project` nie ma ani `lock_version`, ani `updated_at`, więc żaden mechanizm aplikacyjny nie wykryje zapisu ze starej aplikacji (FR-003) | Sam `lock_version` — nie spełnia FR-003, czyli głównego celu US1 |
| Kolumna sterowana przez bazę, nie przez ActiveRecord | Musi działać dla klienta, który o niej nie wie (EF) | Trigger — bardziej inwazyjny, trudniejszy w utrzymaniu i przeglądzie |
| Zmiany schematu współdzielonej bazy | Bez `lock_version` i `people` nie da się spełnić US1 ani US3 | Brak — dane muszą gdzieś mieszkać; ryzyko ograniczone zgodą użytkownika i oceną wpływu |
