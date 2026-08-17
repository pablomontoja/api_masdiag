# Contract: endpointy uwierzytelniania i konwencje namespace'u `lab_sample`

**Feature**: 006-labsample-api-foundation | **Date**: 2026-08-14

---

## Konwencje namespace'u

| Element | Ustalenie |
|---|---|
| Prefiks URL | `/lab_sample/...` |
| Moduł Ruby | `LabSample::` (katalogi `lab_sample/` — wymóg Zeitwerk) |
| Uwierzytelnianie | `Authorization: Bearer <token>` |
| Format | JSON |
| Autoryzacja | Pundit; brak uprawnień → **403** (nie 422 jak w namespace'ach legacy) |
| Brak uwierzytelnienia | **401** |
| Konflikt współbieżności | **409** |
| Błąd walidacji | **422** |

### Koperta błędu — jedna dla całego namespace'u

W repozytorium współistnieją dziś trzy formaty (`{message:}`, `{error:}`,
`{errors:, error_full_messages:}`). Dla `lab_sample` obowiązuje jeden:

```json
{
  "error": {
    "code": "stale_record",
    "message": "Rekord został zmieniony przez innego użytkownika.",
    "details": {}
  }
}
```

Kody: `unauthorized`, `forbidden`, `not_found`, `validation_failed`, `stale_record`.

---

## `POST /lab_sample/sessions` — logowanie

**Żądanie** (bez uwierzytelnienia):
```json
{ "login": "jkowalski", "password": "..." }
```

**200 OK**:
```json
{
  "token": "…",
  "user": {
    "id": 42,
    "login": "jkowalski",
    "first_name": "Jan",
    "last_name": "Kowalski",
    "role": 2,
    "has_smart_card": true
  }
}
```

**401** — błędny login, błędne hasło **lub** konto nieaktywne. Komunikat **identyczny**
we wszystkich trzech przypadkach (FR-006 — nie ujawniać, który element zawiódł):
```json
{ "error": { "code": "unauthorized", "message": "Nieprawidłowe dane logowania." } }
```

**Wymagania**:
- **weryfikacja dwuformatowa** (research R1, R1a, R1b):
  1. jeśli `encrypted_password` jest niepuste → bcrypt (`BCrypt::Password.new(...) == password`)
     — format używany przez `labpanel`;
  2. w przeciwnym razie → PBKDF2-HMAC-SHA1, 10 000 iteracji, 64 B, base64
     — format aplikacji desktopowej;
- **bez gemu Devise** — sam `bcrypt`, już obecny w `Gemfile`;
- porównanie PBKDF2 w czasie stałym (`ActiveSupport::SecurityUtils.secure_compare`);
  bcrypt ma stały czas we własnym operatorze `==`;
- **czas odpowiedzi nie może zdradzać, którym formatem dysponuje konto** — przy nieistniejącym
  loginie wykonać atrapę weryfikacji, żeby uniknąć ataku czasowego;
- pole `login` przyjmuje **login lub adres e-mail** (pracownicy panelu webowego znają swój e-mail);
- utworzenie `Session` z `owner` = pracownik;
- **hasło nigdy nie trafia do logów** — filtrowanie parametrów.

---

## `DELETE /lab_sample/sessions/current` — wylogowanie

Bearer wymagany. **204 No Content**; usuwa sesję. Ponowne użycie tokenu → 401. (FR-009)

---

## Kontrakt zapisu z kontrolą współbieżności

Dotyczy wszystkich zasobów zapisywalnych w tym namespace (od modułu Projekty).

**Odczyt** zwraca oba znaczniki:
```json
{ "Id": 7, "Name": "…", "lock_version": 3, "updated_marker": "2026-08-14T21:15:02Z" }
```

**Zapis** odsyła oba:
```json
{ "project": { "Name": "…" }, "lock_version": 3, "updated_marker": "2026-08-14T21:15:02Z" }
```

**409 Conflict** — gdy którykolwiek się nie zgadza:
```json
{
  "error": {
    "code": "stale_record",
    "message": "Rekord został zmieniony przez innego użytkownika. Odśwież dane.",
    "details": { "current_lock_version": 4 }
  }
}
```

**Dlaczego dwa znaczniki**: `lock_version` wykrywa konflikt między klientami API;
`updated_marker` (sterowany przez MySQL) wykrywa zapis ze starej aplikacji desktopowej,
która o obu kolumnach nie wie. Uzasadnienie w `research.md` R2.

---

## Kontrakt `LabSample::BaseController`

```ruby
class LabSample::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_lab_user!
  around_action :with_audited_user

  rescue_from Pundit::NotAuthorizedError,          with: :render_forbidden
  rescue_from ActiveRecord::StaleObjectError,      with: :render_conflict
  rescue_from ActiveRecord::RecordNotFound,        with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid,         with: :render_validation_failed

  private

  def current_lab_user = @current_session&.owner
  alias_method :pundit_user, :current_lab_user
end
```

**Wymagania**:
- dziedziczy **wprost** z `ActionController::API` — nie z `ApplicationController`
  (ten wymusza HTTP Basic dla wszystkich żądań);
- ustawia `Current.lab_user` na czas żądania;
- ustawia autora audytu (`Audited.store[:audited_user]`) i **czyści go po żądaniu**
  (`CurrentAttributes` i `Audited.store` są wątkowe — wyciek między żądaniami przypisałby
  zmianę niewłaściwej osobie);
- odrzuca żądanie, gdy właściciel sesji nie jest pracownikiem laboratorium.

---

## Kontrakt niezmienności dla istniejących klientów (FR-008, SC-005)

| Namespace | Uwierzytelnianie | Musi działać bez zmian |
|---|---|---|
| `v1`, `fv1`, `nume`, `lalen`, `masdiag`, `masdiag_mailer`, `regspec`, `patient_portal` | HTTP Basic (`ApiAccount`) | ✅ |
| `toxo` | Bearer (`Session` → `Contractor`) | ✅ — **największe ryzyko**, dotyka go migracja `sessions` |
| `webhook` | Bearer (token statyczny) | ✅ |

Zmiana `sessions` na polimorficzne to jedyna modyfikacja dotykająca działającego klienta.
Wymaga pełnej regresji `spec/requests/toxo/` przed i po.
