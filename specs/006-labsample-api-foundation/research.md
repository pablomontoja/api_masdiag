# Phase 0: Research — Fundament API dla aplikacji laboratoryjnej

**Feature**: 006-labsample-api-foundation | **Date**: 2026-08-14

Wszystkie ustalenia zweryfikowane na kodzie (`api_masdiag`, `labsample`, `masdiag_com`).
Polecenia weryfikujące podano przy każdym punkcie.

---

## R1. Uwierzytelnianie pracownika bez resetu haseł

**Decision**: Weryfikacja hasła w Ruby przez `OpenSSL::PKCS5.pbkdf2_hmac_sha1`,
10 000 iteracji, długość 64 B, salt i hash kodowane base64.

**Rationale**: `labsample/LabSample.Bll/Security/PasswordHasher.cs` używa `Rfc2898DeriveBytes`
(PBKDF2-HMAC-SHA1) ze stałymi: `SaltSize = 32`, `HashSize = 64`, `HashIter = 10000`;
salt i hash zapisywane jako base64. Model `User` w api_masdiag mapuje tabelę `Users`
z kolumnami `Password`, `Salt`, `Role`, `IsActive`, `HasSmartCard`.

```ruby
expected = Base64.strict_encode64(
  OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, Base64.decode64(user.Salt), 10_000, 64)
)
ActiveSupport::SecurityUtils.secure_compare(expected, user.Password)
```

Porównanie **musi** używać `secure_compare` (czas stały), a nie `==`.

**Konsekwencje**:
- pracownicy logują się dotychczasowymi hasłami — spełnia FR-005 i SC-002;
- zmiana hasła w starej aplikacji pozostaje ważna dla API (ten sam algorytm, ta sama tabela);
- reguła siły hasła (regex w `PasswordHasher.cs`) jest potrzebna dopiero przy zmianie hasła
  przez API — poza zakresem tej funkcji.

**Alternatives considered**:
- *Wymuszenie resetu haseł i przejście na bcrypt* — odrzucone: łamie SC-002, wymaga akcji
  od każdego pracownika, a stara aplikacja nadal musiałaby działać ze starym algorytmem.
- *Reużycie `ApiAccount` (`has_secure_password`)* — odrzucone: `ApiAccount` jest przywiązane
  do `Contractor` (klient zewnętrzny), nie do pracownika laboratorium; audyt na poziomie
  pracownika byłby niemożliwy.

**Weryfikacja**: `grep -n "HashIter\|SaltSize\|HashSize" labsample/LabSample.Bll/Security/PasswordHasher.cs`

### R1a. Uzupełnienie: w tabeli `Users` istnieją DWA systemy uwierzytelniania

Zgłoszona obserwacja potwierdzona w całości. Tabela `Users` zawiera równolegle:

| System | Pola | Kto używa |
|---|---|---|
| **C# / PBKDF2** | `Login`, `Password`, `Salt` | aplikacja desktopowa LabSample |
| **Devise / bcrypt** | `email`, `encrypted_password`, `reset_password_token`, `reset_password_sent_at`, `remember_created_at`, `sign_in_count`, `current_sign_in_at`, `last_sign_in_at`, `current_sign_in_ip`, `last_sign_in_ip`, `password_changed_at`, `type` | `labpanel` |

`labpanel/app/models/user.rb`:
```ruby
class User < ApplicationRecord
  self.table_name = "Users"
  self.primary_key = "Id"
  devise :database_authenticatable, :recoverable, :trackable, :validatable,
         :timeoutable, stretches: 13
end
```

**Stan uwierzytelniania na tabeli `Users` w całym ekosystemie** (zweryfikowany):

| Aplikacja | Mechanizm | Tabela |
|---|---|---|
| LabSample (C#) | PBKDF2, 10 000 iteracji | `Users` |
| `labpanel` | Devise, bcrypt `stretches: 13` | `Users` |
| `indclients2` | **brak uwierzytelniania** — model tylko do odczytu | `Users` |
| `intranet` | Devise | własna baza `intranetDB` |
| `order-panel` | Devise | własna tabela `order_panel_users` |
| `api_masdiag` | brak — model `User` bez logiki logowania | `Users` |

**Wniosek**: ten sam pracownik ma dziś **dwa niezależne hasła** — jedno do aplikacji desktopowej,
drugie do panelu webowego. Zmiana jednego nie wpływa na drugie. To realny dług, ale jego usunięcie
**nie należy do zakresu tej funkcji** — patrz R1b.

---

### R1b. Czy ujednolicić logowanie? — decyzja

**Decision**: Tak, docelowo **bcrypt (`encrypted_password`) jako jedyny mechanizm**, ale
wprowadzany **dwufazowo**, a nie w tej funkcji. W ramach 006 API weryfikuje **oba** formaty,
przy czym `encrypted_password` ma pierwszeństwo.

**Rationale**:

Docelowym formatem musi być bcrypt, nie PBKDF2, z trzech powodów:
1. to standard Railsów, którym posługują się wszystkie pozostałe aplikacje ekosystemu;
2. bcrypt jest funkcją zaprojektowaną do haseł (adaptacyjny koszt), PBKDF2-HMAC-**SHA1**
   z 10 000 iteracji jest dziś słabym parametrem;
3. kolumny Devise **już istnieją i są wypełnione** dla części pracowników — nie trzeba
   niczego dodawać do schematu.

Natomiast **nie da się przełączyć jednym ruchem**, bo aplikacja desktopowa C# czyta
`Password`/`Salt` i będzie to robić do końca migracji (miesiące). Usunięcie PBKDF2 teraz
zablokowałoby logowanie do LabSample.

**Strategia dwufazowa:**

*Faza 1 (ta funkcja, 006)* — API weryfikuje oba formaty:
```
jeśli encrypted_password niepuste  → bcrypt (zgodność z labpanel)
w przeciwnym razie                 → PBKDF2 (zgodność z LabSample C#)
```
Efekt: pracownik loguje się do nowej aplikacji **tym hasłem, które ma z labpanel**, a jeśli go
nie ma — dotychczasowym z aplikacji desktopowej. Zero resetów (SC-002), zero zmian schematu.

*Faza 2 (osobna funkcja, po wycofaniu LabSample C#)* — jedyny format to bcrypt:
- przy każdym udanym logowaniu PBKDF2 zapisać hasło również jako `encrypted_password`
  (transparentna migracja, bez udziału pracownika);
- po wygaszeniu aplikacji desktopowej wyzerować `Password`/`Salt`;
- ujednolicić `stretches` z labpanel (13).

**Ważne zastrzeżenie**: `api_masdiag` **nie dodaje gemu Devise**. Devise obsługuje sesje
przeglądarkowe (ciasteczka, widoki, `warden`), a to jest API tokenowe. Do weryfikacji hasła
w formacie Devise wystarczy `BCrypt::Password.new(user.encrypted_password) == password`,
a `bcrypt` jest już w `Gemfile` (linia 51). Dodanie Devise wprowadziłoby zależność, której
99% nie byłoby używane, i kolidowałoby z uwierzytelnianiem tokenowym.

**Konsekwencja dla `stretches`**: labpanel używa `stretches: 13`, co jest kosztem *zapisu*
zaszytym w samym hashu. Weryfikacja odczytuje koszt z hasha, więc API nie musi go znać —
istotne dopiero przy zapisywaniu haseł w fazie 2.

**Alternatives considered**:
- *Dodać Devise do api_masdiag* — odrzucone: biblioteka sesji przeglądarkowych w API tokenowym.
- *Tylko PBKDF2 (pierwotna decyzja R1)* — odrzucone po tej analizie: ignoruje fakt, że część
  pracowników ma już hasło bcrypt z labpanel, i utrwala dług zamiast go zmniejszać.
- *Tylko bcrypt, natychmiastowe wycofanie PBKDF2* — odrzucone: zablokowałoby logowanie
  do działającej aplikacji desktopowej.
- *Wspólna usługa uwierzytelniania dla wszystkich aplikacji (SSO)* — sensowne docelowo,
  ale to osobny projekt wykraczający poza fundament; do rozważenia po migracji.

**Weryfikacja**: `grep -n "devise" labpanel/app/models/user.rb Gemfile`;
`sed -n '/create_table "Users"/,/^  end/p' db/schema.rb`

---

## R2. Kontrola współbieżności — najtrudniejsza decyzja tej funkcji

**Decision**: Dwa niezależne sygnały:
1. `lock_version` (ActiveRecord optimistic locking) — konflikt **nowa ↔ nowa**;
2. kolumna znacznika z `ON UPDATE CURRENT_TIMESTAMP` na poziomie MySQL — konflikt **stara ↔ nowa**.

**Rationale**: To jedyne ryzyko w całym przedsięwzięciu mogące **cicho uszkodzić dane pacjentów**,
więc rozwiązanie musi obejmować także zapisy spoza API.

**Kluczowe ustalenie z kodu C#** — encja `labsample/LabSample.Dal/Entities/Project.cs` ma
16 pól i **nie zawiera ani `updated_at`, ani `lock_version`**:

```
Id, Name, Description, WithCutter, PlateDimensionX, PlateDimensionY, Prefix,
PdfNameOfAnalysis, PdfDescription, InjectionVolume, IsActive, FinalProtocoleHeader,
ResponsiblePersonEmail, HasSelectableAnalytes, Analytes, SurveyQuestions
```

Wynika z tego, że zapis ze starej aplikacji:
- nie podniesie `lock_version` → optimistic locking Railsów milczy;
- nie zmieni `updated_at` → porównanie znacznika w kodzie Ruby też milczy.

**Żaden mechanizm aplikacyjny nie wykryje konfliktu stara ↔ nowa**, a to jest dokładnie
scenariusz opisany w FR-003. Dlatego wykrywanie musi zejść do warstwy bazy danych.

Kolumna zadeklarowana jako `ON UPDATE CURRENT_TIMESTAMP` jest aktualizowana przez sam MySQL
przy każdym `UPDATE` wiersza — **niezależnie od tego, czy klient wie o jej istnieniu**.
Entity Framework zaktualizuje ją mimowolnie, po prostu zapisując rekord.

Przepływ zapisu w API:
1. klient odczytuje rekord i otrzymuje `lock_version` oraz znacznik;
2. przy zapisie odsyła oba;
3. API odrzuca zapis, jeśli którykolwiek się nie zgadza (`409 Conflict`);
4. klient odświeża dane i ponawia.

**Alternatives considered**:
- *Sam `lock_version`* — odrzucone: nie spełnia FR-003, czyli głównego celu US1.
- *Trigger `BEFORE UPDATE`* — odrzucone: bardziej inwazyjny w bazie współdzielonej przez
  9 aplikacji, trudniejszy w przeglądzie i utrzymaniu; `ON UPDATE CURRENT_TIMESTAMP` daje ten sam
  efekt jako deklaracja kolumny.
- *Blokady pesymistyczne (`SELECT ... FOR UPDATE`)* — odrzucone: aplikacja desktopowa trzyma
  formularz otwarty długo; blokada wisiałaby minutami.
- *Rezygnacja z wykrywania na czas przejściowy* — odrzucone: to właśnie ryzyko, dla którego
  ta funkcja powstała.

**Otwarta kwestia do potwierdzenia przy implementacji**: czy `ON UPDATE CURRENT_TIMESTAMP`
można nałożyć na **istniejącą** kolumnę `updated_at` w `Projects`, czy bezpieczniej dodać nową
kolumnę techniczną. Nałożenie na `updated_at` zmieniłoby zachowanie dla pozostałych aplikacji
Rails piszących do `Projects` (Rails i tak ustawia `updated_at` sam, więc różnica byłaby
kosmetyczna) — ale **to zmiana semantyki kolumny w bazie współdzielonej i wymaga zgody**.

**Weryfikacja**: `grep -E "public" labsample/LabSample.Dal/Entities/Project.cs`

---

## R3. Audyt — tabela już istnieje

**Decision**: Gem `audited` (~> 5.8), bez tworzenia migracji dla tabeli `audits`.

**Rationale**: `db/schema.rb:512` zawiera **kompletną tabelę `audits`** z układem kolumn dokładnie
odpowiadającym gemowi `audited`:

```
auditable_id, auditable_type, associated_id, associated_type,
user_id, user_type, username, action, audited_changes,
version, comment, remote_address, request_uuid, created_at
```
wraz z indeksami `auditable_index`, `associated_index`, `user_index`, `index_audits_on_created_at`,
`index_audits_on_request_uuid`.

Jednocześnie:
- gemu `audited` **nie ma w Gemfile** (`grep -n "audited" Gemfile` → brak);
- **nic w `app/` ani `lib/` go nie używa** (`grep -rn "audited\|Audit" app/ lib/` → brak wyników).

Ktoś przygotował tabelę i nie dokończył pracy. Wystarczy dodać gem — **zero migracji dla audytu**,
co istotnie zmniejsza zakres zmian w bazie współdzielonej.

Wersja ~> 5.8 wybrana dla zgodności z `masdiag_com`, gdzie ten sam wzorzec działa produkcyjnie.

**Uwaga o zakresie audytu**: `audited` rejestruje wyłącznie zapisy przechodzące przez
ActiveRecord. Zapisy z aplikacji desktopowej (EF) **nie zostawią śladu** — i to jest w porządku,
bo właśnie po to migrujemy ruch do API. Ślad będzie kompletny dla modułów już przeniesionych.
Warto to wprost zakomunikować, żeby nie powstało złudzenie pełnego audytu od pierwszego dnia.

**Weryfikacja**: `sed -n '512,535p' db/schema.rb`; `grep -n "audited" Gemfile`

---

## R4. Jednolita tożsamość autora — `Person`

**Decision**: Przenieść wzorzec `Person` + `Personable` z `masdiag_com`, dostosowany do MySQL.

**Rationale**: W `masdiag_com` działa produkcyjnie:

```ruby
class Person < ApplicationRecord
  audited
  belongs_to :personable, polymorphic: true
  validates :personable_id, uniqueness: { scope: :personable_type }
end

module Personable
  included do
    has_one :person, as: :personable, required: true, inverse_of: :personable
    before_validation :prep_person
  end
  def prep_person = build_person if new_record?
end
```

Włączają go cztery typy kont (`User`, `HcpAccount`, `ApiAccount`, `PersonalAccount`) — czyli jedna
tożsamość dla różnych typów aktorów. W api_masdiag potrzebne dla `User` (pracownicy)
i `ApiAccount` (klienci partnerscy).

**Różnica techniczna**: `masdiag_com` to PostgreSQL z kluczami UUID (`id: :uuid`,
`gen_random_uuid()`), api_masdiag to MySQL z `bigint`. **Migrację napisać od nowa**, nie kopiować.

**Uwaga do rozstrzygnięcia**: `Personable` ma `required: true` i tworzy `Person` w
`before_validation` tylko dla nowych rekordów. W api_masdiag `Users` i `ApiAccounts` **już
istnieją** — potrzebny jest backfill dla rekordów historycznych, inaczej istniejący pracownicy
nie przejdą walidacji przy pierwszym zapisie. Ujęte jako osobne zadanie.

**Alternatives considered**:
- *Zapis `user_type`/`user_id` wprost w `audits`, bez `Person`* — prostsze, ale `audited` i tak
  to potrafi; `Person` daje dodatkowo stabilny punkt odniesienia dla przyszłych powiązań
  i jest już sprawdzony w innej aplikacji zespołu.

**Weryfikacja**: `cat masdiag_com/app/models/person.rb masdiag_com/app/models/concerns/personable.rb`

---

## R5. Sesje polimorficzne

**Decision**: `sessions.contractor_id` → `sessions.owner_type` / `sessions.owner_id`,
z backfillem `owner_type = "Contractor"`.

**Rationale**: Obecny schemat (`db/schema.rb`):
```
contractor_id integer NOT NULL, ip_address, user_agent, token NOT NULL,
last_active_at, created_at, updated_at
index [contractor_id], unique index [token]
```

Jedynym konsumentem jest `Toxo::BaseController#authenticate_by_token!`
(`Session.includes(:contractor).find_by(token:)`). Zmiana na polimorficzne `owner` pozwala
przechowywać w jednej tabeli sesje kontraktorów (toxo) i pracowników (LabSample) — zgodnie
z wcześniejszym ustaleniem.

**Wymagania migracji**:
1. dodać `owner_type`, `owner_id`;
2. backfill: `owner_type = "Contractor"`, `owner_id = contractor_id`;
3. indeks `[owner_type, owner_id]`; zachować unikalny indeks na `token`;
4. `contractor_id` zostawić tymczasowo (możliwość wycofania), usunąć w osobnym kroku;
5. `Toxo::BaseController#current_contractor` musi działać bez zmian.

**Ryzyko**: to jedyna zmiana dotykająca **działającego** klienta produkcyjnego. Stąd umieszczenie
jej na końcu kolejności prac i wymóg pełnej regresji `spec/requests/toxo/`.

**Uwaga bezpieczeństwa (poza zakresem, warto odnotować)**: obecny `Session` przechowuje token
jawnie i wyszukuje go zwykłym `find_by` (porównanie nie w czasie stałym), bez wygasania mimo
kolumny `last_active_at`. Nowy mechanizm nie powinien tego pogłębiać; poprawa istniejącego
zachowania to osobna decyzja.

**Weryfikacja**: `grep -A 11 'create_table "sessions"' db/schema.rb`;
`cat app/controllers/toxo/base_controller.rb`

---

## R6. Kształt namespace'u `lab_sample`

**Decision**: `LabSample::BaseController < ActionController::API`, Bearer + Pundit,
**bez** ponownego użycia `app/controllers/concerns/toxo/*`.

**Rationale**: Wzorzec `Toxo::BaseController` jest właściwy koncepcyjnie: dziedziczy wprost
z `ActionController::API` (omija globalny HTTP Basic z `ApplicationController`), uwierzytelnia
tokenem Bearer, aliasuje `pundit_user`. Ale zgodnie z wcześniejszym ustaleniem użytkownika
skala zmian dla LabSample wymaga dedykowanych rozwiązań — `Toxo::Paginatable`/`Searchable`/`Sortable`
okażą się za ciasne (operacje wsadowe, filtrowanie po statusach pomiarów, eksporty).

Różnice wobec toxo:
- `current_lab_user` zamiast `current_contractor`; `Current.lab_user` dla dostępu w modelach;
- powiązanie żądania z autorem audytu (`Audited.store[:audited_user]`);
- ujednolicona koperta błędów (w repo współistnieją dziś trzy: `{message:}`, `{error:}`,
  `{errors:, error_full_messages:}`) — dla nowego namespace'u przyjąć jedną i udokumentować;
- `403` dla braku autoryzacji (namespace'y legacy zwracają `422`, co jest niepoprawne).

**Weryfikacja**: `cat app/controllers/toxo/base_controller.rb`;
`ls app/controllers/concerns/toxo/`

---

## Podsumowanie wpływu na bazę współdzieloną

Zasada z `CLAUDE.md`: zmiana schematu `LabSample` wymaga jawnej zgody użytkownika.

| Migracja | Wpływ na inne aplikacje | Ryzyko |
|---|---|---|
| `people` (nowa tabela) | Żaden — nikt jej nie używa | Niskie |
| `audits` | **Brak migracji** — tabela już istnieje | Brak |
| `sessions` → polimorficzne | Dotyczy `toxo` (jedyny konsument) | **Średnie** — wymaga backfillu i regresji |
| `Projects` + `lock_version` | Nowa kolumna z domyślną wartością; EF ją zignoruje | Niskie |
| `Projects` znacznik `ON UPDATE` | Zmiana semantyki kolumny **lub** nowa kolumna | **Do rozstrzygnięcia** (R2) |

Trzy migracje wymagają zgody; jedna odpada dzięki istniejącej tabeli `audits`.
