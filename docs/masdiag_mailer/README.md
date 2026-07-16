# Namespace `masdiag_mailer`

## Przegląd

Namespace `masdiag_mailer` obsługuje wysyłkę powiadomień e-mail związanych z próbkami diagnostycznymi, zamówieniami sklepowymi i formularzem kontaktowym strony masdiag.pl. Wejściem do namespace jest pojedynczy kontroler `MasdiagMailer::EmailsController` (`app/controllers/masdiag_mailer/emails_controller.rb`), który tylko enqueue'uje joby lub od razu wywołuje mailery — cała logika biznesowa (kogo powiadomić, jaką treścią) leży w klasach `app/jobs/masdiag_mailer/` i `app/mailers/masdiag_mailer/`.

Główni konsumenci API:
- **LabSample** — system laboratoryjny, wywołuje endpointy dot. próbek (`send_all_mails`, `send_acceptance_notifications`, `send_cancellation_notifications`, `send_notification_after_delayed_reg`).
- **indclients2** — wywołuje `after_sample_registration` oraz `send_error_notifications`.
- **www.masdiag.pl** — formularz kontaktowy (`masdiag_website_contact_form`).
- Sklep (`shop_order`) — `after_new_order_save`, `shipping_after_new_order`.

### Autoryzacja

Każda akcja jest chroniona przez `MasdiagCheck` (`app/controllers/concerns/masdiag_check.rb`), który w `before_action` wymaga `Current.api_account.institution.id == 1` — dostęp mają tylko konta API należące do instytucji Masdiag.

## Routes i akcje kontrolera

Wszystkie trasy zdefiniowane w `config/routes.rb` w bloku `namespace :masdiag_mailer, defaults: {format: :json}`.

| Route | Akcja kontrolera | Job/Mailer wywoływany |
|---|---|---|
| `GET send_all_mails` | `send_all` | `ContractorResultsNotifierJob.perform_later`, `PatientResultsNotifierJob.perform_later` |
| `POST send_acceptance_notifications` | `send_acceptance_notifications` | `SendAcceptanceNotificationsJob.perform_later(params["sample_ids"])` |
| `POST send_cancellation_notifications` | `send_cancellation_notifications` | `SendCancellationNotificationsJob.perform_later(params["sample_ids"])` |
| `POST send_error_notifications` | `send_error_notifications` | `SendErrorNotificationsMailer.send_mail(params.to_unsafe_hash).deliver_later` |
| `POST send_notification_after_delayed_reg` | `send_notification_after_delayed_reg` | `SendNotificationAfterDelayedRegJob.perform_later(params[:sample_id])` |
| `POST after_sample_registration` | `after_sample_registration` | `ThreeMethylDopaMailer#after_sample_registration` (jeśli próbka ma pomiar w `ProjectId: 25`) albo `IndMailer#after_sample_registration` |
| `POST after_new_order_save` | `after_new_order_save` | `IndMailer#after_new_order_save(params[:shop_order_id])` |
| `POST shipping_after_new_order` | `shipping_after_new_order` | `IndMailer#shipping_after_new_order(params[:shop_order_id])` |
| `POST masdiag_website_contact_form` | `masdiag_website_contact_form` | `MasdiagPlContactFormMailer.send_mail({name:, email:, message:})` |

Endpoint `send_all` ma dodatkowy rate-limit — odrzuca wywołania częstsze niż raz na 60 sekund (`Rails.configuration.last_use_of_send_all_mail`).

## Joby (`app/jobs/masdiag_mailer/`)

### `ContractorResultsNotifierJob`

Bez argumentów. Wyszukuje `Contractor`ów z `are_notifications_enabled: true`, następnie niewysłane pliki (`OnlineFile`, `is_notification_send: false`) powiązane z ich pacjentami, grupuje `measurement_id` po kontrahencie i dla każdej grupy woła `ContractorResultNotificationMailer.send_mail(contractor_id, file_ids)` — jedno powiadomienie e-mail może zawierać wiele plików wyników.

### `PatientResultsNotifierJob`

Bez argumentów. Analogicznie do powyższego, ale w kontekście pacjenta — wyszukuje niewysłane pliki (`is_patient_notification_send: false`) dla pacjentów z `send_results_on_mail: true`, poprawnym adresem e-mail i wykluczeniem `ContractorId: 125`. Dodatkowo filtruje przez `should_send_notification?` (blokuje szpitale poza instytucją 69 — Szpital Bielański, oraz kontrahentów z własnym `api_account`). W odróżnieniu od `ContractorResultsNotifierJob` wysyła **jeden e-mail na jeden plik** — `PatientResultNotificationMailer.send_mail(patient_id, file_id)` przyjmuje pojedynczy identyfikator, nie kolekcję.

### `SendAcceptanceNotificationsJob`

Argument: `sample_ids` (tablica). Dla każdej próbki pomija przypadki bez pacjenta oraz kontrahentów posiadających własne `api_account` (sami obsługują powiadomienia). Jeśli pacjent ma e-mail, wywołuje `SendAcceptanceNotificationsMailer.send_mail_to_patient(sample_id)`. Błędy przechwytywane globalnym `rescue` wysyłają e-mail przez `SendErrorNotificationsMailer`.

### `SendCancellationNotificationsJob`

Argument: `sample_ids` (tablica). Najbardziej złożony job w namespace — dla każdej próbki rozstrzyga, kogo i jaką treścią powiadomić, na podstawie instytucji, typu opakowania (`ReservedSampleCode`/`Package`/`Product`) i zakresu kodu kreskowego. Przypadki są sprawdzane sekwencyjnie (pierwsze dopasowanie wygrywa, `next` kończy iterację dla danej próbki):

| # | Warunek | Akcja |
|---|---|---|
| 1 | Pudełko retail sale, `InstitutionId: 32` (LEKAM) | `send_mail_to_patient_standard_dbs_paper` do pacjenta |
| 2 | Pudełko retail sale, `InstitutionId: 34` (AQIPHARM) | `send_mail_to_dziopa` (wewnętrzne) + `send_mail_to_patient_standard_dbs_paper` do pacjenta |
| 3 | Pudełko retail sale, `parent_id == nil`, pacjent nie-wirtualny | `send_mail_to_patient` |
| 4 | Pudełko retail sale, `parent_id != nil` (zapasowe), pacjent nie-wirtualny | `send_mail_to_patient_standard_dbs_paper` |
| 5 | Pudełko non-retail, `parent_id == nil`, ma `test_transaction` (partnerzy.masdiag.pl) | `send_mail_to_patient` |
| 6 | Próbka powiązana z `shop_order` (Diagnostyka Precyzyjna) | `send_mail_to_patient` |
| 7 | Numeryczny kod w zakresie 5000–15373 | `send_mail_to_contractor` |
| 8 | Numeryczny kod w zakresie 20000–22059 (LEKAM, pierwsze zamówienie) | `send_mail_to_contractor` |
| 9 | Bibuła nie z pudełka (produkt inny niż typ 1/4) | `send_mail_to_contractor` do lekarza |
| 10 | Jak wyżej, do pacjenta, poza instytucją 87 (HolisticaMed) | `send_mail_to_patient_standard_dbs_paper` |

Każdy przypadek pomija próbki bez adresu e-mail (`patient_email != nil`, dla przypadku 10 dodatkowo `!= "null"`). Błędy trafiają do `SendErrorNotificationsMailer`.

### `SendNotificationAfterDelayedRegJob`

Argument: `sample_id`. Wyszukuje pomiary (`Measurement`) danej próbki, które nie mają statusu 5 i których próbka ma już `AcceptanceDate`, następnie grupuje po `project.responsible_person_email` i dla każdej grupy wysyła `SendNotificationAfterDelayedRegMailer.send_mail(email, measurement_ids)`.

### `CheckRscAssignementJob`

Argument: `sample_id`. Nie jest wywoływany przez `EmailsController` — działa niezależnie w cyklu przyjęcia próbki. Sprawdza, czy nośnik (`ReservedSampleCode`) przyjętej próbki ma przypisane badania (`reserved_tests`/`measurements`); jeśli nie i status próbki różny od 4, wysyła alert przez `RscNotAssignedMailer.send_mail(sample.rsc)`. Ma własny `retry_on StandardError` z raportowaniem do Sentry.

## Mailery (`app/mailers/masdiag_mailer/`)

| Mailer | Metoda(y) | Adresat | Uwagi |
|---|---|---|---|
| `ContractorResultNotificationMailer` | `send_mail(contractor_id, file_ids)` | kontrahent | Zwraca `nil` jeśli powiadomienia wyłączone lub kontrahent ma `api_account`; wspiera własny szablon HTML per instytucja (`contractor_email_template_body`, renderowany przez `ERB.new(...).result(binding)`); po wysyłce oznacza pliki jako wysłane (`is_notification_send`). |
| `PatientResultNotificationMailer` | `send_mail(patient_id, file_id)` | pacjent | Zwraca `nil` dla pustego e-maila, wyłączonej zgody, lub szpitali poza instytucją 69; dołącza ulotki (`attach_proper_leaflet`) w zależności od `ProjectId` (15/16/17); w produkcji może użyć dedykowanego SMTP per instytucja; wspiera własny szablon HTML per instytucja. |
| `SendAcceptanceNotificationsMailer` | `send_mail_to_patient(sample_id)` | pacjent | Jedyna metoda tej klasy. |
| `SendCancellationNotificationsMailer` | `send_mail_to_patient(sample_id)`, `send_mail_to_contractor(sample_id, email)`, `send_mail_to_dziopa(sample_id)`, `send_mail_to_patient_standard_dbs_paper(sample_id)` | pacjent / kontrahent / wewnętrznie (Dariusz Kołodyński) | `send_mail_to_dziopa` ma zaszyty adres `dariusz.kolodynski@masdiag.pl`. |
| `SendErrorNotificationsMailer` | `send_mail(params)` | `webadmin@masdiag.pl` | `params` to dowolny Hash — renderowany jako lista klucz/wartość w widoku. |
| `ThreeMethylDopaMailer` | `after_sample_registration(sample_id)` | pacjent | Wysyłana tylko dla próbek z pomiarem w `ProjectId: 25`; dołącza wygenerowane PDF (`RegistrationConfirmationThreeOmdPdf`). |
| `IndMailer` | `after_new_order_save(shop_order_id)`, `shipping_after_new_order(shop_order_id)`, `after_sample_registration(sample_id)` | klient sklepu / `logistyka@masdiag.pl` / pacjent | `after_new_order_save` generuje token rejestracyjny i link (`root_address` różny dla dev/test vs. produkcji). |
| `MasdiagPlContactFormMailer` | `send_mail(msg)` | `pomoc@masdiag.pl` | `msg` to Hash z `:name`, `:email`, `:message`; `reply_to` ustawiony na e-mail nadawcy formularza. |
| `SendNotificationAfterDelayedRegMailer` | `send_mail(email, measurements_arr)` | odpowiedzialna osoba (`project.responsible_person_email`) | Zwraca wcześnie, jeśli e-mail jest pusty. |
| `RscNotAssignedMailer` | `send_mail(rsc)` | `pawel.swider@masdiag.pl` | Adres odbiorcy jest na stałe zaszyty w kodzie. |

## Szablony e-maili (widoki)

Widoki w `app/views/mailers/masdiag_mailer/` dzielą się na dwie rodziny wizualne:

- **Brandowana ("v1template")** — pełny szablon z `<div id="v1wrapper">`, logo, niebieskim banerem i stopką firmową: `send_acceptance_notifications_mailer/send_mail_to_patient`, `ind_mailer/after_sample_registration`, `ind_mailer/after_new_order_save`, `ind_mailer/shipping_after_new_order`, `three_methyl_dopa_mailer/after_sample_registration` (uproszczony wariant tej rodziny).
- **Niestylizowana** — proste nagłówki `<h3>`/tabele bez brandingu: `contractor_result_notification_mailer`, `patient_result_notification_mailer`, `send_error_notifications_mailer`, `send_notification_after_delayed_reg_mailer`, `masdiag_pl_contact_form_mailer`, `rsc_not_assigned_mailer`, oraz wszystkie cztery metody `send_cancellation_notifications_mailer` (`send_mail_to_patient`, `send_mail_to_contractor`, `send_mail_to_dziopa`, `send_mail_to_patient_standard_dbs_paper`).

Pliki `ind_mailer/after_new_order_save.erb` i `ind_mailer/shipping_after_new_order.erb` używają rozszerzenia `.erb` (nie `.html.erb`) — jedyne takie przypadki w tym namespace.

## Rails Mailer Previews (`test/mailers/previews/masdiag_mailer/`)

| Plik preview | Klasa | Metody |
|---|---|---|
| `result_notification_mailer_preview.rb` | `ResultNotificationMailerPreview` | `contractor_result_notification_mailer`, `contractor_result_notification_lekam`, `patient_result_notification_mailer_dp`, `patient_result_notification_mailer_ogen`, `patient_result_notification_mailer_lekam` |
| `send_acceptance_notification_mailer_preview.rb` | `SendAcceptanceNotificationMailerPreview` | `send_mail_to_patient` |
| `cancellation_notification_mailer_preview.rb` | `CancellationNotificationMailerPreview` | `send_mail_to_patient`, `send_mail_to_contractor`, `standard_cancellation_notification` (→ `send_mail_to_patient_standard_dbs_paper`), `send_mail_to_dziopa` |
| `send_error_notifications_mailer_preview.rb` | `SendErrorNotificationsMailerPreview` | `send_mail` |
| `after_sample_registration_mailer_preview.rb` | `AfterSampleRegistrationMailerPreview` | `regular_sample` (→ `IndMailer#after_sample_registration`), `three_methyl_dopa` (→ `ThreeMethylDopaMailer#after_sample_registration`) |
| `ind_mailer_preview.rb` | `IndMailerPreview` | `after_new_order_save`, `shipping_after_new_order` |
| `masdiag_pl_contact_form_mailer_preview.rb` | `MasdiagPlContactFormMailerPreview` | `send_mail` |
| `notification_after_delayed_reg_mailer_preview.rb` | `NotificationAfterDelayedRegMailerPreview` | `send_mail` |
| `rsc_not_assigned_mailer_preview.rb` | `RscNotAssignedMailerPreview` | `alert_email` |

Każda z 10 klas mailerów ma pokrycie w co najmniej jednym pliku preview. Nowe metody mailerów powinny dostawać odpowiadający wpis preview w tym samym pliku co siostrzane metody tej klasy.

## Testy

- **Request specs**: `spec/requests/masdiag_mailer/emails_controller_spec.rb` — pokrywa wszystkie 8 aktywnych akcji kontrolera (happy path + błędy).
- **Job specs**: `spec/jobs/masdiag_mailer/` zawiera specs dla `ContractorResultsNotifierJob`, `PatientResultsNotifierJob`, `SendAcceptanceNotificationsJob`, `SendNotificationAfterDelayedRegJob`. Brak dedykowanych specs dla `SendCancellationNotificationsJob` i `CheckRscAssignementJob`.
- **Mailer specs**: katalog `spec/mailers/` nie istnieje — żaden mailer nie ma dedykowanego testu weryfikującego treść/temat/załączniki wygenerowanej wiadomości; pokrycie jest wyłącznie pośrednie przez joby/request specs, które zazwyczaj stubują wywołanie mailera.
