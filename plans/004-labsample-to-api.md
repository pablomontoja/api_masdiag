# Plan: Migracja LabSample (C# WPF) z Entity Framework na api_masdiag

## Context

`labsample` (C# WPF, .NET Framework 4.7.2, C# 7.3) to aplikacja, od której zaczął się cały system —
i jedyna, która wciąż pisze do bazy `LabSample` bezpośrednio przez Entity Framework 6.

**Cel:** przekierować ją na `api_masdiag`, żeby domknąć audyt zmian rekordów. Dziś audyt jest
praktycznie niemożliwy, bo EF omija walidacje i callbacki ActiveRecord — zapisy z C# nie zostawiają
śladu, kto i co zmienił.

**Kluczowe ustalenie: to migracja ścieżki dostępu, nie danych.**
`config/database.yml` w api_masdiag wskazuje na tę samą bazę `LabSample` (mysql2), a `app/models/`
zawiera już ~45 modeli ActiveRecord odwzorowujących 40 encji EF niemal 1:1
(`sample.rb`, `measurement.rb`, `result.rb`, `analyte_result.rb`, `plate.rb`, `patient.rb`,
`user.rb`, `project.rb`, `institution.rb`, `contractor.rb`, `online_file.rb`, …).
Nie trzeba niczego przenosić — trzeba przekierować ruch.

**Zakres tego dokumentu:** zmiany architektoniczne. Roadmapa serwis-po-serwisie i szczegółowa
specyfikacja endpointów — osobno, po zatwierdzeniu architektury.

---

## Stan zastany — dlaczego migracja przyrostowa jest wykonalna

Architektura C# jest znacznie lepiej uporządkowana niż typowa aplikacja WPF i to ona umożliwia
migrację etapami:

| Fakt | Znaczenie dla migracji |
|------|------------------------|
| Warstwy App → Bll → Dal, 31 serwisów za interfejsami `IXxxSvc` | Interfejsy = gotowy szew wymiany |
| **369 wywołań `UnitOfWork.Execute` w 44 plikach — wszystkie w Bll, zero w App** | Cała powierzchnia EF w jednej warstwie |
| 67 DTO w `Bll/Dto/`; interfejsy operują na DTO, nie na encjach | DTO = gotowy kontrakt JSON |
| `Bll/Services/NotificationSvc.cs` i `MailerSvc.cs` implementują swój interfejs **wyłącznie przez HTTP**, bez EF | Wzorzec docelowy już działa produkcyjnie |
| `Bll/Services/ApiServiceBase.cs` — HttpClient + auth + JSON, `BaseUrl` = `https://api.masdiag.pl` | Fundament do rozbudowy |
| StructureMap, jeden punkt rejestracji: `Bll/Configuration/DependencyContainer.cs` | Podmiana implementacji = jedna linia |
| Zero raw SQL, zero procedur składowanych (jedyny wyjątek: `MySqlBulkLoader`) | Migracja przewidywalna |
| Narzędzia `Cutter`, `SmartCard`, `ConfigWriter`, `Updater` nie referencują `Dal` | Poza zakresem migracji |

Skala: ~99k linii C# w 831 plikach; sam Bll to ~59k w 318 plikach; 38 ViewModeli; 68 plików XAML.

---

# Część I — strona C#

## Architektura docelowa: dwa nowe projekty

```
LabSample.App (UI)                       ← docelowo Avalonia
        │  używa IXxxSvc
        ▼
LabSample.Contracts        ◄─── NOWY DLL #1  (interfejsy IXxxSvc + DTO + enumy)
        ▲                                     zero zależności, czysty kontrakt
        │ implementują
   ┌────┴───────────────────┐
   │                        │
LabSample.Bll          LabSample.ApiClient  ◄─── NOWY DLL #2
(stare, EF6)           (nowe, HTTP → api_masdiag)
   │                        │
LabSample.Dal (EF6)     HTTP / JSON
   │                        │
   └────────► MySQL ◄───────┴──── api_masdiag (Rails)
```

Sens rozdziału: dziś „kontrakt" (interfejsy + DTO) i „implementacja" (EF) mieszkają w tym samym
projekcie `LabSample.Bll`. Dopóki tak jest, nie da się mieć dwóch implementacji obok siebie.

### DLL #1 — `LabSample.Contracts` (hurtownia kontraktów)

Wydzielenie z `LabSample.Bll` tego, co jest **kontraktem**, a nie implementacją:

- `Services/Interfaces/*.cs` — 33 interfejsy `IXxxSvc`
- `Dto/*` — 67 DTO
- wspólne enumy

**Zasada: projekt bez żadnych referencji** — bez Dal, EF, StructureMap, AutoMapper.
Obie implementacje (EF i HTTP) zależą od kontraktu, a nie od siebie nawzajem. To Dependency
Inversion: warstwa wysokopoziomowa (App) i niskopoziomowa (dostęp do danych) zależą od tej samej
abstrakcji.

**Krok 0 — rozcięcie zależności.** Kontrakt nie jest dziś czysty:

- 13 DTO + 2 interfejsy mają `using LabSample.Dal.Enums;`
- 3 pliki mają `using LabSample.Dal.Entities;`:
  - `Bll/Dto/ReservedSampleCode/AddReservedSampleCodeDto.cs`
  - `Bll/Services/Interfaces/ISampleSvc.cs`
  - `Bll/Services/Interfaces/IPlateMeasurementSvc.cs`

Enumy istnieją **zduplikowane** w `Dal/Enums/` i `Bll/Enums/`
(np. `MaterialTypeEnum` vs `MaterialType`, `MeasurementStatusEnum` vs `MeasurementStatus`).

Do zrobienia: skonsolidować enumy w `Contracts`, usunąć duplikaty, zweryfikować 3 pliki z encjami.
W `ISampleSvc` encje **nie wyciekają do sygnatur metod** — to najprawdopodobniej martwe `using`.
Szacunkowo godziny, nie tygodnie.

### DLL #2 — `LabSample.ApiClient` (komunikacja z api_masdiag)

Druga implementacja tych samych interfejsów, oparta na HTTP:

```
LabSample.ApiClient/
  Http/
    IApiConnection.cs        # abstrakcja transportu (testowalność bez sieci)
    ApiConnection.cs         # HttpClient: Bearer, retry, timeout, 401 → ponowne logowanie
    ApiResult.cs / ApiResult<T>.cs
    ApiException.cs
  Auth/
    ITokenProvider.cs
    SessionTokenProvider.cs  # token bieżącej sesji użytkownika
  Services/
    SampleApiSvc.cs          # : ISampleSvc
    PatientApiSvc.cs         # : IPatientSvc
    ...
  Serialization/
    JsonSettings.cs          # Newtonsoft: konwencja nazw, format dat
```

**Wzorce projektowe:**

1. **Adapter** — najważniejszy. Każdy `XxxApiSvc` adaptuje REST-owe API do istniejącej sygnatury
   `IXxxSvc`. ViewModel nie wie, że cokolwiek się zmieniło.
2. **Strategy + DI** — wybór implementacji (EF vs HTTP) per serwis w `DependencyContainer`.
   Precedens tego wzorca jest już w repo: `ExternalApiClients/Strategy/`.
3. **Facade** — `ApiConnection` ukrywa HttpClient, nagłówki, serializację i mapowanie błędów;
   serwisy nie dotykają HTTP bezpośrednio.

**Dlaczego `IApiConnection` jako osobna abstrakcja:** przy 10 plikach testowych na ~21k linii logiki
to jedyny sposób, żeby testować `XxxApiSvc` bez stawiania serwera.

### Przełączanie EF ↔ HTTP

W `Bll/Configuration/DependencyContainer.cs` zamiast:

```csharp
config.For<ISampleSvc>().Use<SampleSvc>();            // EF
```

warunkowo:

```csharp
if (ApiMigration.IsEnabled("Sample"))
    config.For<ISampleSvc>().Use<SampleApiSvc>();     // HTTP
else
    config.For<ISampleSvc>().Use<SampleSvc>();        // EF
```

Flaga per serwis (wpis w `ConfigEntry` albo App.config) pozwala migrować serwis po serwisie,
wdrażać etapami i **natychmiast cofnąć się przy awarii — bez rekompilacji**.

### Kolejność zależności projektów

```
LabSample.Contracts   → (nic)
LabSample.ApiClient   → Contracts
LabSample.Bll         → Contracts, Dal          (docelowo znika)
LabSample.Dal         → EF6                     (docelowo znika)
LabSample.App         → Contracts, ApiClient, Bll (przejściowo)
```

Docelowo: `LabSample.App → Contracts + ApiClient`, a `Bll` i `Dal` zostają usunięte
razem z ~100 migracjami EF.

---

## Modernizacja platformy: .NET 10 + Avalonia

Stan na sierpień 2026: **.NET 10 to aktualne LTS**, Avalonia 11.12 wspiera .NET 10 i jego szablony,
a migracje WPF → Avalonia są rutynową praktyką produkcyjną. .NET Framework 4.7.2 jest w trybie
podtrzymania — nie dostaje nowych funkcji.

**Rekomendacja: rozdzielić modernizację od migracji do API na dwie niezależne osie.**
Można je prowadzić równolegle, ale **nie mieszać w jednym kroku** — inaczej przy awarii nie da się
ustalić, czy winna jest zmiana platformy, czy zmiana ścieżki dostępu do danych.

Proponowana kolejność:

1. **Nowe DLL-e od razu jako .NET Standard 2.0** (`Contracts`, `ApiClient`).
   Kluczowa decyzja: .NET Standard 2.0 jest kompatybilny **jednocześnie** z .NET Framework 4.7.2
   i z .NET 10. Dzięki temu obecna aplikacja WPF korzysta z nich jeszcze przed jakąkolwiek migracją
   platformy, a przy przejściu na .NET 10 nie wymagają żadnych zmian.
2. **Migracja do API** (opisana wyżej) — wciąż na starym WPF, z nowymi DLL-ami.
3. **Przejście UI na .NET 10** — dopiero po odcięciu EF. Bez EF6 (który w tej formie nie działa
   na .NET 10) migracja platformy jest znacznie prostsza. To główny argument za tą kolejnością.
4. **WPF → Avalonia** na końcu. Avalonia jest inspirowana WPF, również oparta na XAML + MVVM,
   więc 38 ViewModeli dziedziczących `BaseViewModel` (INotifyPropertyChanged + `SetProperty<T>()`
   + `RelayCommand`) przenosi się w dużej mierze bez zmian.

**Realny koszt migracji UI — nie należy go ukrywać:** ~14k linii w plikach `.xaml.cs` (code-behind),
w tym `MainWindow.xaml.cs` (2 808 linii), `ResultsView.xaml.cs` (1 235), `RegProtocolView.xaml.cs` (811),
`PlatesListView.xaml.cs` (693). To nie jest przeklejenie XAML-a — logikę z code-behind trzeba
najpierw przenieść do ViewModeli. Do tego zależności platformowe wymagające zamienników:
`LabSample.SmartCard` (PKCS#11), `LabSample.Cutter` (COM/serial), iTextSharp/MigraDoc, EPPlus,
drukowanie etykiet.

**Korzyść dodatkowa:** Avalonia jest wieloplatformowa — otwiera drogę na Linuksa w laboratorium.

---

# Część II — strona api_masdiag

## Namespace `LabSample`

```
app/controllers/lab_sample/base_controller.rb   # klasa Ruby: LabSample::BaseController
app/controllers/lab_sample/*_controller.rb
app/policies/lab_sample/
app/resources/lab_sample/
app/services/lab_sample/
spec/requests/lab_sample/
```

**Uwaga nazewnicza:** moduł Ruby nazywa się `LabSample` (CamelCase), ale pliki i katalogi muszą być
`lab_sample/` (snake_case) — tego wymaga autoloader Zeitwerk. `namespace :lab_sample` w routes
generuje URL-e `/lab_sample/...`; jeśli w URL-u ma być `/LabSample/`, wymaga to jawnego `path:`
— do decyzji przy implementacji.

**Nie kopiować `app/controllers/concerns/toxo/`.** Zakres zmian jest na tyle duży, że
`Toxo::Paginatable` / `Searchable` / `Sortable` okażą się za ciasne — LabSample potrzebuje
własnych rozwiązań (operacje wsadowe, filtrowanie po statusach pomiarów, eksporty, płytki).
Z namespace'u `toxo` warto wziąć jedynie **koncepcję**: osobny `BaseController` dziedziczący
wprost z `ActionController::API` (omijający globalny HTTP Basic z `ApplicationController`),
uwierzytelnianie Bearer i Pundit. Wzorzec: `app/controllers/toxo/base_controller.rb`.

## Audyt: model `Person` (wzorzec z masdiag_com)

To jest właściwy cel całej migracji. W `../masdiag_com` działa sprawdzony wzorzec ujednoliconej
tożsamości aktora:

```ruby
# masdiag_com/app/models/person.rb
class Person < ApplicationRecord
  audited
  belongs_to :personable, polymorphic: true
  validates :personable_id, uniqueness: { scope: :personable_type }

  def fullname = personable&.fullname
end

# masdiag_com/app/models/concerns/personable.rb
module Personable
  extend ActiveSupport::Concern

  included do
    has_one :person, as: :personable, required: true, inverse_of: :personable
    before_validation :prep_person
  end

  private

  def prep_person
    build_person if new_record?
  end
end
```

W masdiag_com `Personable` włączają cztery różne typy kont: `User`, `HcpAccount`, `ApiAccount`,
`PersonalAccount` — czyli **jedna tożsamość dla różnych typów aktorów**. Dokładnie o to chodzi
przy audycie: ślad zmiany wskazuje na `Person`, niezależnie od tego, czy działał pracownik
laboratorium, konto API czy pacjent.

Audyt realizuje gem `audited` (~> 5.8) + tabela `audits` z polimorficznym `user_type`/`user_id`,
`audited_changes` (JSON), `version`, `request_uuid`, `remote_address`.

**Do przeniesienia do api_masdiag:**

- tabela `people` (`personable_type`/`personable_id`) + model `Person` + concern `Personable`
- `include Personable` w `User` (pracownicy laboratorium) i `ApiAccount` (klienci API)
- gem `audited` — **w api_masdiag go dziś nie ma**, trzeba dodać, razem z tabelą `audits`
- ustawianie audytującego aktora w `LabSample::BaseController` (`Audited.store[:audited_user]`)

**Różnica techniczna do uwzględnienia:** masdiag_com to PostgreSQL z kluczami UUID
(`id: :uuid`, `gen_random_uuid()`), a api_masdiag to MySQL z kluczami integer/bigint.
Migracje trzeba napisać od nowa na `bigint` — nie kopiować z masdiag_com.

Dopiero to domyka cel: skoro token niesie tożsamość konkretnego pracownika, a `Person` ujednolica
typy aktorów, każdy zapis przez API odpowiada na pytanie „kto zmienił ten rekord".

## Sesje polimorficzne

Zmiana `sessions.contractor_id` → `sessions.owner_type` / `sessions.owner_id`, żeby toxo
(Contractor) i LabSample (User) korzystały z jednej tabeli tokenów:

```ruby
class Session < ApplicationRecord
  belongs_to :owner, polymorphic: true
  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end
```

Obecny schemat (`db/schema.rb`): `contractor_id` NOT NULL, unique index na `token`.
Migracja musi:
- backfillować istniejące wiersze na `owner_type = "Contractor"`,
- zachować działanie `Toxo::BaseController#current_contractor`,
- zachować unique index na `token`.

Warto rozważyć powiązanie sesji z `Person` zamiast bezpośrednio z ownerem — spina to
uwierzytelnianie z audytem w jednym miejscu.

## Logowanie bez resetu haseł użytkowników

`Bll/Security/PasswordHasher.cs` używa `Rfc2898DeriveBytes`, czyli **PBKDF2-HMAC-SHA1,
10 000 iteracji, salt 32 B, hash 64 B, oba kodowane base64**.

Model `User` już istnieje w api_masdiag (`app/models/user.rb`, tabela `Users`, kolumny
`Password` / `Salt` / `Role` / `IsActive` / `HasSmartCard`), więc weryfikacja w Ruby:

```ruby
expected = Base64.strict_encode64(
  OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, Base64.decode64(user.Salt), 10_000, 64)
)
ActiveSupport::SecurityUtils.secure_compare(expected, user.Password)
```

**Logowanie przenosi się bez resetu haseł.** Regułę siły hasła (regex w tym samym pliku) przenieść
razem z obsługą zmiany hasła. `UserSvc` obsługuje też wygasanie haseł (`LastPasswordChangeAt`,
`PasswordChangeRevokedAt`) — to również trafia do API. Smart card zostaje po stronie klienta;
do API idzie wyłącznie wynik uwierzytelnienia.

---

## Główne ryzyka

- **~700 wywołań `.Include(...)` + lazy loading** (`public virtual` nav props na encjach).
  Kod swobodnie chodzi po grafie obiektów (`result.Measurement.Sample.Patient`) także poza blokiem
  `UnitOfWork` — płaskie DTO z HTTP tego nie zapewnią. **Największe pojedyncze ryzyko.**
  Wymaga świadomej decyzji o kształcie DTO (płaskie vs zagnieżdżone) i przeglądu miejsc,
  które polegają na leniwym ładowaniu.

- **Tylko 10 plików testowych na ~21k linii logiki Bll** — praktycznie brak siatki bezpieczeństwa
  dla refaktoryzacji tej skali. Stąd nacisk na `IApiConnection` (testy bez sieci) i na flagi
  per serwis (szybki rollback).

- **Sync-over-async.** Interfejsy `IXxxSvc` są synchroniczne, HTTP jest z natury asynchroniczny,
  a w App jest ~70 miejsc z `Task.Run` / `Dispatcher.Invoke`. `.Result` / `.Wait()` na wątku UI
  grozi zakleszczeniem. Do rozstrzygnięcia: konsekwentne `ConfigureAwait(false)` w całym ApiClient
  czy stopniowa zmiana interfejsów na async.

- **Operacje wsadowe.** `ResultSvc` (3 749 linii) i `Bll/ResultImport/` robią masowe zapisy
  wieloencyjne w jednej transakcji (`dc.BulkInsert`, `UnitOfWork.Execute(..., save: false)`).
  Wymagają dedykowanych endpointów transakcyjnych — nie N pojedynczych żądań REST.

- **`OnlineFileSvc` ma 7 651 linii** (blobs + szyfrowanie + wsadowa resynchronizacja).
  Zasługuje na osobny plan migracji.

- **Zderzenie z walidacjami Railsów.** Dziś EF omija callbacki i walidacje ActiveRecord
  (`Sample#before_validation` upcase `Code`, `Measurement#set_time_stamps`, `Patient` IsVirtual).
  Po przejściu na API zaczną obowiązywać, a w bazie są wiersze, które ich nie spełniają.
  Przed migracją serwisów rdzeniowych zaplanować przegląd danych.

- **Znalezisko bezpieczeństwa — zadanie niezależne, do zrobienia od razu:**
  `Bll/Services/ApiServiceBase.cs` (linie 21–29) zawiera zahardkodowane loginy i hasła produkcyjne
  do `api.masdiag.pl`. Są w historii gita → wymagana rotacja poświadczeń i przeniesienie
  do konfiguracji zewnętrznej.

---

## Weryfikacja

Ten dokument jest deliverablem architektonicznym — testów nie uruchamiamy. Weryfikacja dotyczy
kolejnych etapów implementacji:

**Krok 0 (Contracts):**
- rozwiązanie buduje się po wydzieleniu `LabSample.Contracts`
- `LabSample.Contracts.csproj` nie ma żadnych `ProjectReference` ani referencji do EF
- `dotnet test tests/LabSample.Bll.UnitTests/` przechodzi bez zmian

**Krok 1 (fundament API):**
- migracja `sessions` na polimorficzne `owner_*` + backfill; istniejące sesje toxo działają
- `bundle exec rspec spec/requests/toxo/` — regresja na toxo po zmianie `sessions`
- endpoint logowania: poprawne hasło → 200 + token; błędne → 401; nieaktywny użytkownik → 403
- weryfikacja PBKDF2 na prawdziwym rekordzie z tabeli `Users` (bez zmiany hasła)
- `Person` tworzony automatycznie dla `User` i `ApiAccount`; wpis w `audits` po zapisie przez API

**Krok 2 (ApiClient):**
- `XxxApiSvc` testowany przez podstawiony `IApiConnection`, bez sieci
- przełączenie flagi per serwis zmienia implementację bez rekompilacji
- ten sam scenariusz biznesowy daje identyczny wynik przez EF i przez HTTP
