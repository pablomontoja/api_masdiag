# Namespace `masdiag`

## Przegląd

Namespace `masdiag` grupuje wewnętrzne operacje Masdiag: wyzwalanie wysyłki wyników, obsługę zmiany statusu próbki, konfigurację endpointu wyników, magazyn (stock room), **sprawdzanie wersji i pobieranie instalatora aplikacji desktopowej LabSample.Updater** oraz — najnowszy element — **ujednolicony system powiadomień cyklu życia próbki** dla systemu laboratoryjnego LabSample.

Namespace obsługuje pięć kontrolerów w `app/controllers/masdiag/`:

- `Masdiag::NotificationController` (`notification_controller.rb`) — starsze endpointy wyzwalające wysyłkę wyników i reakcję na zmianę statusu.
- `Masdiag::NotificationsController` (`notifications_controller.rb`) — **nowe**, zunifikowane endpointy zdarzeń powiadomień. LabSample zgłasza wyłącznie ZDARZENIE (np. `sample_accepted`), a wybór szablonu (rodzina `:toxo` vs `:lab`) i odbiorcy następuje po stronie tej aplikacji, w warstwie `app/services/notifications/`.
- `Masdiag::SetupController` (`setup_controller.rb`) — konfiguracja adresu endpointu wyników konta API.
- `Masdiag::StockRoomsController` (`stock_rooms_controller.rb`) — operacje magazynowe (stock room) dla aplikacji zamówień (order_panel).
- `Masdiag::LabsampleController` (`labsample_controller.rb`) — sprawdzanie najnowszej wersji i URL instalatora `.7z` aplikacji desktopowej LabSample.Updater, na podstawie modelu `LabsampleRelease`. Szczegóły → [docs/masdiag/labsample-releases.md](labsample-releases.md).

### Autoryzacja

Każda akcja w czterech z pięciu kontrolerów jest chroniona przez `MasdiagCheck` (`app/controllers/concerns/masdiag_check.rb:1`), który w `before_action :only_masdiag_access` wymaga `Current.api_account.institution.id == 1` — dostęp mają tylko konta API należące do instytucji Masdiag. Przy braku uprawnień zwraca `422 Unprocessable Entity` z komunikatem `"You do not have access to this part of Masdiag API."`.

> **Wyjątek:** `Masdiag::LabsampleController` **nie** dołącza `MasdiagCheck` — chroni go wyłącznie standardowe HTTP Basic z `ApplicationController#authenticate`, więc dostęp mają wszystkie konta API, nie tylko instytucji Masdiag. Zgodne z zamierzeniem (desktopowa aplikacja LabSample.Updater loguje się danymi zwykłego konta API), ale warto o tym pamiętać przy analizie uprawnień tego namespace'u.

## Routes i akcje kontrolera

Wszystkie trasy zdefiniowane w `config/routes.rb` w bloku `namespace :masdiag, defaults: {format: :json}` (`config/routes.rb:143`).

| Route | Akcja kontrolera | Wymagane parametry | Job/Serwis wywoływany | Kody odpowiedzi |
|---|---|---|---|---|
| `POST /masdiag/setup/result_post_endpoint` | `SetupController#result_post_endpoint` | `data: {url, username, password}` | ustawia atrybuty na `Current.api_account` | `200` |
| `POST /masdiag/notifications/trigger` | `NotificationController#trigger` | brak | `Cerascreen::Labordatenbank::GetResultsJob`, `Hl7MinioScannerJob`, `Hl7LinkPendingJob`, `Hl7RetryFailedJob`, `Notification::SendResultJob`, `Notification::LalenResultSender` | `200` / `500` |
| `POST /masdiag/notifications/sample_status_changed/:sample_id` | `NotificationController#sample_status_changed` | `sample_id` (w ścieżce) | `Lock::CheckJob`, `MasdiagMailer::CheckRscAssignementJob`, `Notification::SampleChangedJob` | `200` / `500` |
| `POST /masdiag/sample_accepted` | `NotificationsController#sample_accepted` | `sample_id` | `Notifications::SampleAcceptedJob` | `200` OK / `422` sample not found |
| `POST /masdiag/sample_rejected` | `NotificationsController#sample_rejected` | `sample_id` | `Notifications::SampleRejectedJob` | `200` OK / `422` sample not found |
| `POST /masdiag/result_available` | `NotificationsController#result_available` | `sample_id` | `Notifications::ResultAvailableJob` | `200` OK / `422` sample not found |
| `POST /masdiag/registration_reminder` | `NotificationsController#registration_reminder` | `sample_id` **lub** `code` | `Notifications::RegistrationReminderJob` | `200` OK / `422` sample not found |
| `POST /masdiag/stock_room/stock_out_by_packages` | `StockRoomsController#stock_out_by_packages` | `package_ids: []`, `institution_id`, `comment` | `StockOutByPackagesService` | `200` / `500` |
| `POST /masdiag/stock_room/stock_out_by_shipment` | `StockRoomsController#stock_out_by_shipment` | `shipment_id`, `institution_id`, `comment` | `StockOutByPackagesService` | `200` / `500` |
| `POST /masdiag/stock_room/back_to_stock_by_shipment/:shipment_id` | `StockRoomsController#back_to_stock_by_shipment` | `shipment_id` (w ścieżce) | `BackToStockByPackagesService` | `200` / `500` |
| `GET /masdiag/stock_room/is_package_in_stock/:id` | `StockRoomsController#is_package_in_stock` | `id` (Package, w ścieżce) | `Package#stock_room_item` | `200` / `500` |
| `GET /masdiag/labsample/latest_version` | `LabsampleController#latest_version` | brak | `LabsampleRelease.latest` | `200` (`version: nil`, gdy brak rekordów) |
| `GET /masdiag/labsample/download_url` | `LabsampleController#download_url` | brak | `LabsampleRelease.latest` + `rails_blob_url` | `200` (`url: nil`, gdy brak rekordu/załącznika) |

> Uwaga: zdarzenie **A — `sample_registration_confirmation`** oraz **D — `registration_reminder_final`** nie mają endpointów HTTP. `sample_registration_confirmation` jest wyzwalane wewnątrz aplikacji (po rejestracji próbki w portalu Toxo), a `registration_reminder_final` jest jobem cyklicznym (patrz `config/recurring.yml`).

## Kontrolery

### `Masdiag::NotificationController` (`notification_controller.rb`)

Dwie akcje, obie opatrzone komentarzem `# TODO - it need to be tested` w kodzie:

- **`trigger`** (`notification_controller.rb:6`) — bez parametrów. Enqueue'uje zestaw jobów pobierania/przetwarzania wyników (Cerascreen, HL7), a następnie wybiera pomiary (`Measurement`) w statusie 5 dla kontrahentów posiadających `api_account`, odfiltrowuje już wysłane (`ResultSendingEvent`, `sent_through: 6`) i dla każdego woła `Notification::SendResultJob`. Osobno obsługuje próbki Lalen (`V1::Common::LALEN_INSTITUTION_IDS`, `AuthorizedAt` od 2024-09-09) przez `Notification::LalenResultSender`. Błędy raportowane do Sentry, zwraca `500`.
- **`sample_status_changed`** (`notification_controller.rb:43`) — parametr `sample_id`. Enqueue'uje `Lock::CheckJob`, `MasdiagMailer::CheckRscAssignementJob` oraz `Notification::SampleChangedJob` dla wskazanej próbki. Błędy raportowane do Sentry, zwraca `500`.

### `Masdiag::NotificationsController` (`notifications_controller.rb`)

Cienki kontroler zunifikowanego systemu powiadomień. Wszystkie akcje tylko walidują istnienie próbki i enqueue'ują odpowiedni job z `app/jobs/notifications/`; cała logika (wybór szablonu, odbiorcy, idempotencja) leży w warstwie serwisów.

- **`sample_accepted` / `sample_rejected` / `result_available`** — używają prywatnego `enqueue_by_id` (`notifications_controller.rb:35`): szukają `Sample.find_by(Id: params[:sample_id])`, przy braku zwracają `422 {error: "sample not found"}`, w innym wypadku enqueue'ują odpowiedni job po `sample.Id` i zwracają `json_response("OK")`.
- **`registration_reminder`** (`notifications_controller.rb:24`) — przyjmuje `sample_id` **lub** `code` (dostarczona, niezarejestrowana próbka może być znana LabSample tylko po kodzie). Sprawdza istnienie próbki przez `Sample.exists?(Id: ...) || Sample.exists?(Code: ...)`; przy braku `422`, w innym wypadku enqueue'uje `Notifications::RegistrationReminderJob` z identyfikatorem.

### `Masdiag::SetupController` (`setup_controller.rb`)

Jednolinijkowy kontroler dziedziczący po `V1::SetupController` i dołączający `MasdiagCheck`. Akcja `result_post_endpoint` (z klasy bazowej) zapisuje na `Current.api_account` adres URL, login i hasło endpointu, na który klient odbiera wyniki (`data: {url, username, password}`), i zwraca aktualne wartości z zamaskowanym hasłem (`password_shadow`).

### `Masdiag::StockRoomsController` (`stock_rooms_controller.rb`)

Operacje magazynowe wykorzystywane przez aplikację order_panel:

- **`is_package_in_stock`** (`stock_rooms_controller.rb:11`) — dla `Package.find(:id)` sprawdza `stock_room_item` (brak `date_out` i `remaining_quantity > 0`) i zwraca `{package_in_stock: true/false}` (+ nazwa magazynu, gdy w magazynie).
- **`stock_out_by_packages`** (`stock_rooms_controller.rb:38`) — zdejmuje z magazynu i przypisuje do instytucji wskazane `package_ids` przez `StockOutByPackagesService`. Komentarz w kodzie sugeruje, że endpoint prawdopodobnie nie jest używany.
- **`stock_out_by_shipment`** (`stock_rooms_controller.rb:55`) — ustala `package_ids` po `shipment_id` i deleguje do `StockOutByPackagesService` (endpoint używany przez order_panel).
- **`back_to_stock_by_shipment`** (`stock_rooms_controller.rb:72`) — ustala `package_ids` po `shipment_id` i zawraca opakowania do magazynu przez `BackToStockByPackagesService`. Komentarz w kodzie sugeruje, że endpoint prawdopodobnie nie jest używany.

Odpowiedzi z serwisów zwracają `200` z `notice` lub `500` z `errors`.

### `Masdiag::LabsampleController` (`labsample_controller.rb`)

Odpytywane przez LabSample.Updater (aplikacja desktopowa C#) przed każdym uruchomieniem okna logowania, żeby sprawdzić dostępność nowszej wersji instalatora. Pełny opis modelu `LabsampleRelease`, task `labsample_releases:add` do dodawania wydań oraz szczegóły obu akcji → [docs/masdiag/labsample-releases.md](labsample-releases.md).

## Zunifikowany system powiadomień (rodzina `masdiag/notifications`)

### Zasada działania

LabSample zgłasza wyłącznie **zdarzenie** cyklu życia próbki. To ta aplikacja rozstrzyga, jaki szablon i do kogo wysłać. Rozpoznawane zdarzenia (`Notifications::EventDispatcher::KNOWN_EVENTS`):

| Symbol | Zdarzenie | Wyzwalacz |
|---|---|---|
| A | `sample_registration_confirmation` | wewnętrznie po rejestracji próbki (job) |
| B | `sample_accepted` | `POST /masdiag/sample_accepted` |
| C | `registration_reminder` | `POST /masdiag/registration_reminder` |
| D | `registration_reminder_final` | job cykliczny (`config/recurring.yml`) |
| E | `sample_rejected` | `POST /masdiag/sample_rejected` |
| F | `result_available` | `POST /masdiag/result_available` |

### Przepływ

```
Controller → Notifications::<Event>Job → Notifications::EventDispatcher
   → TemplateResolver (rodzina :toxo | :lab)
   → RecipientResolver (adres odbiorcy)
   → Sender (idempotencja przez Note + audyt) → mailer
```

### Warstwa serwisów (`app/services/notifications/`)

- **`EventDispatcher`** (`event_dispatcher.rb`) — punkt wejścia. Waliduje zdarzenie względem `KNOWN_EVENTS`, ustala rodzinę przez `TemplateResolver.family_for(sample)` i deleguje:
  - `:toxo` → wyznacza odbiorcę (`RecipientResolver`), buduje `Toxo::SampleNotificationMailer.public_send(event, sample)` i przekazuje do `Sender` (z `family: :toxo`).
  - `:lab` → deleguje do istniejących mailerów/jobów laboratoryjnych (`MasdiagMailer::ContractorResultNotificationMailer`, `SendAcceptanceNotificationsJob`, `SendCancellationNotificationsJob`, `IndMailer#after_sample_registration`). Zdarzenia przypomnień C/D **nie mają** odpowiednika laboratoryjnego i dla instytucji nie-Toxo są pomijane (`Result.new(status: :skipped)`).
- **`TemplateResolver`** (`template_resolver.rb`) — ustala instytucję próbki oraz rodzinę szablonu. Dla próbki zarejestrowanej (pacjent nie-wirtualny) instytucję wyznacza kontraktor pacjenta; dla próbki niezarejestrowanej (pacjent wirtualny) — kod próbki → `ReservedSampleCode.find_by(Code:)` → `Institution` (nigdy `ContractorId` pacjenta wirtualnego). Rodzina to `:toxo`, gdy `institution.id.in?(V1::Common::TOXO_INSTITUTION_IDS)`, w innym wypadku `:lab`.
- **`RecipientResolver`** (`recipient_resolver.rb`) — wyznacza adres e-mail odbiorcy (lub `nil` → pominięcie):
  - Zdarzenia przypomnień C/D (`REMINDER_EVENTS`) → `institution.email_for_notifications` (instytucja z kodu → RSC → Institution).
  - Pozostałe zdarzenia (A/B/E/F) → adres kontraktora zamawiającego (`sample.patient.contractor.email`), bramkowany:
    - globalną flagą kontraktora `are_notifications_enabled` (nadrzędna),
    - **oraz** (AND) flagą per-zdarzenie z mapy `EVENT_FLAGS`: `sample_accepted → allow_sample_acceptance_notifications`, `sample_rejected → allow_sample_rejection_notifications`, `result_available → allow_result_notifications`, `sample_registration_confirmation → allow_sample_registration_notifications`.
- **`Sender`** (`sender.rb`) — wysyła pojedyncze powiadomienie idempotentnie:
  1. pomija, gdy brak odbiorcy,
  2. pomija, gdy `Note` dla `(subject_type: "Sample", subject_id, key)` już istnieje (już wysłano),
  3. dostarcza (`deliver_now`),
  4. zapisuje **audyt** przez `Fileable` → `ResultSendingEvent` (`sent_through: 1` = EmailNotification, `sample`, `recipient`, `address`) + `DbFile` z treścią HTML wiadomości,
  5. tworzy `Note` znakujący wysyłkę.
  Wyścig `ActiveRecord::RecordNotUnique` traktowany jest jako pominięcie (`:skipped`).
  Klucze `Note` per zdarzenie (`EVENT_KEYS`, walidowane przez `Note#available_keys`): A → `sample-registration-confirmation-email`, B → `sample-accepted-email`, C → `registration-reminder-email`, D → `registration-reminder-final-email`, E → `sample-rejected-email`, F → `result-available-email`. Klucz jest jednakowy dla obu rodzin szablonów, więc próbka otrzymuje najwyżej jeden e-mail danego typu.
- **`RegistrationRemindersFinder`** (`registration_reminders_finder.rb`) — dla zdarzenia D wyszukuje próbki: dostarczone (`AcceptanceDate` ustawione), niezarejestrowane (`Patients.IsVirtual: true`), należące do instytucji Toxo (kod → `ReservedSampleCode.InstitutionId` ∈ `TOXO_INSTITUTION_IDS`), którym minęło co najmniej **7 dni roboczych** od `AcceptanceDate` (`WORKING_DAYS.business_days.after(...)` z gemu `business_time`) i którym nie wysłano jeszcze przypomnienia powtórnego (brak `Note` o kluczu `registration-reminder-final-email`).

### Joby (`app/jobs/notifications/`)

Wszystkie joby mają `retry_on StandardError, wait: :exponentially_longer, attempts: 5`.

| Job | Zdarzenie | Argument | Zachowanie |
|---|---|---|---|
| `SampleAcceptedJob` | B | `sample_id` | `Sample.find_by(Id:)`, `nil` → return; `EventDispatcher.call(event: :sample_accepted, ...)` |
| `SampleRejectedJob` | E | `sample_id` | jw. dla `:sample_rejected` |
| `ResultAvailableJob` | F | `sample_id` | jw. dla `:result_available` |
| `RegistrationReminderJob` | C | `id_or_code` | `Sample.find_by(Id:) || find_by(Code:)`; `:registration_reminder` |
| `RegistrationReminderFinalJob` | D | brak | iteruje `RegistrationRemindersFinder.call` i dla każdej próbki woła `:registration_reminder_final`; uruchamiany cyklicznie |
| `SampleRegistrationConfirmationJob` | A | `sample_id` | `:sample_registration_confirmation`; łapie `Prawn::Errors::PrawnError`/`IOError` (błąd PDF) i raportuje do Sentry w produkcji, nie przerywając rejestracji |

### Job cykliczny (`config/recurring.yml`)

`Notifications::RegistrationReminderFinalJob` jest zarejestrowany jako `daily_toxo_registration_reminder_final`, kolejka `background`, harmonogram `"0 6 * * *"` (codziennie o 6:00) — dla środowisk `default/development/staging/production` (`config/recurring.yml:78`).

### Instytucje Toxo

Przynależność do rodziny Toxo określa stała `V1::Common::TOXO_INSTITUTION_IDS` (`app/lib/v1/common.rb:22`).

> **Rozbieżność / uwaga:** obecnie `TOXO_INSTITUTION_IDS = [].freeze` — lista jest **pusta**. W praktyce oznacza to, że `TemplateResolver#family` nigdy nie zwróci `:toxo`, więc każde zdarzenie trafia do gałęzi `:lab`. `RegistrationRemindersFinder` przy pustej liście zwraca wprost `Sample.none`, a przypomnienia C/D w gałęzi `:lab` są pomijane. Ścieżka Toxo (mailer `Toxo::SampleNotificationMailer`, wysyłka przez `Sender`) pozostaje nieaktywna do czasu uzupełnienia tej stałej.

## Testy

- **Request specs** (`spec/requests/masdiag/`): `result_available_spec.rb`, `sample_accepted_spec.rb`, `sample_rejected_spec.rb`, `registration_reminder_spec.rb` — pokrywają cztery nowe endpointy `NotificationsController`.
- **Service specs** (`spec/services/notifications/`): `event_dispatcher_spec.rb`, `template_resolver_spec.rb`, `recipient_resolver_spec.rb`, `sender_spec.rb`, `registration_reminders_finder_spec.rb` — pełne pokrycie warstwy serwisów.
- **Job specs** (`spec/jobs/notifications/`): `sample_registration_confirmation_job_spec.rb`, `sample_accepted_job_spec.rb`, `sample_rejected_job_spec.rb`, `result_available_job_spec.rb`, `registration_reminder_job_spec.rb`, `registration_reminder_final_job_spec.rb` — pełne pokrycie sześciu jobów.
- **Mailer specs** (`spec/mailers/toxo/`): `sample_notification_mailer_spec.rb` — weryfikuje tematy, treść (numer próbki, URL portalu, ostrzeżenie o zwrocie, pola identyfikujące przy odrzuceniu) i załącznik PDF dla wszystkich sześciu metod `Toxo::SampleNotificationMailer`.
- **PDF specs** (`spec/pdfs/toxo/`): `order_confirmation_pdf_spec.rb` — renderowanie PDF podsumowania zlecenia.
- **Request spec portalu** (`spec/requests/toxo/samples/registrations_order_confirmation_spec.rb`): enqueue `SampleRegistrationConfirmationJob` po udanej rejestracji, brak enqueue przy błędzie walidacji i przy braku autoryzacji (Bearer/Pundit).

### Braki w pokryciu

- Brak request speca dla `NotificationController#trigger` i `#sample_status_changed` — oba oznaczone w kodzie komentarzem `# TODO - it need to be tested`.
- Brak testów dla `Masdiag::SetupController` (dziedziczona akcja) w kontekście namespace `masdiag`.
- Brak testów dla `Masdiag::StockRoomsController` (`is_package_in_stock`, `stock_out_by_packages`, `stock_out_by_shipment`, `back_to_stock_by_shipment`) oraz serwisów `StockOutByPackagesService` / `BackToStockByPackagesService`.
- Brak request speca dla `Masdiag::LabsampleController` (`latest_version`, `download_url`) — pokryty jedynie pośrednio przez spec taska `labsample_releases:add` (`spec/lib/tasks/labsample_releases_rake_spec.rb`), który nie testuje samego kontrolera.
- Uwaga: ścieżka Toxo (mailer + `Sender`) jest pokryta testami, ale przy pustym `TOXO_INSTITUTION_IDS` nie jest wykonywana produkcyjnie do czasu uzupełnienia stałej.
