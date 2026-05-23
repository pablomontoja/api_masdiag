# Plan: Migracja modeli toxo do ApiModel::Base (wzorzec z plans/005)

## Context

Aplikacja `toxo` (Rails 8.1) ma zostać przekształcona tak, żeby warstwa danych (Sample, Measurement, Patient, Project, ReservedSampleCode) komunikowała się z zewnętrznym Rails API zamiast bezpośrednio z MySQL. Wzorzec implementacji opisuje plans/005: modele dziedziczą z `ApiModel::Base` (HTTP klient oparty na `ActiveModel::Model`) zamiast z `ActiveRecord::Base`.

**Cel:** external Rails API jako shared backend dla toxo web, mobile i docelowego zastępcy C#. Audyt wszystkich zmian danych w jednym miejscu.

**Ustalenia:**
- Session + Contractor zostają jako AR w toxo (auth lokalnie, bez HTTP na każde żądanie)
- Pundit i cała logika Policy przenosi się do API (API zwraca już przefiltrowane dane)
- Cała logika `SamplesController#create` (transakcja + Measurements) → API (`Toxo::Samples::RegistrationsController`)
- Callbacki i walidacje AR → przenoszą się do API
- Enums obsługiwane przez `ActiveModel::Attributes` po stronie toxo (do formularzy/widoków)
- Token auth: `session.token` (istniejący token z tabeli `sessions`) jako Bearer token do API

---

## Architektura docelowa

```
Browser
  │ HTTP (HTML / Turbo)
  ▼
toxo (Rails 8.1)
  ├── Controllers / Views / Helpers        ← zostają
  ├── Session (AR → sessions table)        ← zostaje (auth lokalnie)
  ├── Contractor (AR → Contractors table)  ← zostaje (tymczasowo)
  └── ApiModel::Base (HTTP client)
        ├── Sample        → /toxo/samples/registrations
        ├── Measurement   → read-only /toxo/measurements
        ├── Patient       → /toxo/patients
        ├── Project       → read-only /toxo/projects
        └── ReservedSampleCode → read-only /toxo/reserved_sample_codes
                │ Authorization: Bearer <session.token>
                ▼
        external Rails API
          ├── Toxo::Samples::RegistrationsController  (transakcja Sample+Measurements)
          ├── Toxo::BaseController  (Bearer token auth)
          ├── SamplePolicy / SamplePolicy::Scope  (Pundit)
          ├── Wszystkie AR modele (validations, callbacks, enums)
          └── MySQL (ta sama baza co C#)
```

**Token auth:** `session.token` (już istniejący token w tabeli `sessions`) jest wysyłany jako `Authorization: Bearer <token>` do API. API weryfikuje token przez bezpośrednie zapytanie do tabeli `sessions` (ta sama baza MySQL) i rozpoznaje contractor_id.

---

## Część I: Zmiany w toxo (web app)

### Faza 1: ApiModel::Base — infrastruktura HTTP klienta

**Nowe pliki:**
- `app/models/api_model/base.rb` — wzorzec z plans/005, z Faraday zamiast Net::HTTP
- `app/models/api_model/connection.rb` — Faraday z retry, timeout, Bearer token
- `app/controllers/concerns/api_error_handling.rb` — rescue_from dla ApiModel błędów

**Konfiguracja:**
- `config/credentials.yml` — `api_base_url`
- `Gemfile` — dodać `gem "faraday"`, `gem "faraday-retry"`

**`ApiModel::Base` musi implementować:**
- `self.all(params)`, `self.find(id)`, `self.where(params)`
- `save`, `create`, `update`, `destroy`
- `persisted?`, `to_param` — żeby `form_with(model: @sample)` działał
- `errors` — mapowanie błędów z API response (`422` + JSON) na `ActiveModel::Errors`
- Token z `Current.session.token` wstrzyknięty do każdego żądania

### Faza 2: Enums i typy atrybutów w ApiModel bez AR

`Sample` ma enums: `MaterialType`, `post_examination_procedure`, `infectious_risk`, `execution_mode`. Po migracji:

```ruby
# app/models/sample.rb (nowy — ApiModel)
class Sample < ApiModel::Base
  self.resource_name = "toxo/samples/registrations"

  attribute :Id,                         :integer
  attribute :Code,                       :string
  attribute :MaterialType,               :integer
  attribute :post_examination_procedure, :integer
  attribute :infectious_risk,            :integer
  attribute :execution_mode,             :integer
  attribute :dispatch_date,              :date
  attribute :Lot,                        :string
  attribute :Level,                      :string
  attribute :AcceptanceDate,             :datetime
  attribute :IsWrongRegistration,        :boolean
  attribute :WasWrongRegistration,       :boolean

  # Enum helpers ręcznie (używane tylko w widokach/formularzach)
  MATERIAL_TYPES = MaterialTypes::MODEL_HASH
  POST_EXAMINATION = { immediate_return: 0, storage_and_return: 1, storage_and_disposal: 2 }
  INFECTIOUS_RISK  = { no_information: 0, elevated: 1 }
  EXECUTION_MODE   = { standard: 0, expedited: 1 }

  def material_type_name = MATERIAL_TYPES.key(MaterialType)&.to_s
  def deletable? = AcceptanceDate.nil?
end
```

### Faza 3: Migracja modeli jeden po drugim

**Kolejność (od najprostszego):**

1. **`Project`** — read-only w toxo, brak callbacks, prosta lista do formularza
2. **`Patient`** — read-only z perspektywy toxo
3. **`ReservedSampleCode`** — walidacje przenoszą się do API
4. **`Measurement`** — tworzony zawsze razem z Sample (przez API endpoint), read-only w toxo
5. **`Sample`** — ostatni, najbardziej złożony

### Faza 4: Przebudowa SamplesController

```ruby
def create
  # can_add_samples? sprawdzane lokalnie przez Contractor AR
  unless current_contractor.can_add_samples?
    redirect_to samples_path, alert: t("unauthorized") and return
  end

  @sample = Sample.new(sample_params)

  if @sample.save   # POST /toxo/samples/registrations
    redirect_to sample_path(@sample), notice: t(".success")
  else
    load_projects
    render :new, status: :unprocessable_entity
  end
rescue ApiModel::ServerError
  redirect_to samples_path, alert: t("api_unavailable")
end
```

`@sample.save` → `POST /toxo/samples/registrations` z `project_ids` w body → API owni całą transakcję.

**`index`:** `@samples = Sample.all` → `GET /toxo/samples/registrations` (API zwraca już przefiltrowane dane — Pundit Scope po stronie API).

**`show`:** `@sample = Sample.find(params[:id])` → `GET /toxo/samples/registrations/:id`.

**`destroy`:** `@sample.destroy` → `DELETE /toxo/samples/registrations/:id`.

### Faza 5: Autoryzacja — usunięcie Pundit z toxo

- `app/policies/` → usunięcie (przenoszone do API)
- `ApplicationController` → usunięcie `include Pundit::Authorization`
- Zamiast `policy_scope(Sample)` → `Sample.all` (API filtruje)
- Zamiast `authorize @sample` → lokalny check `current_contractor.can_add_samples?`

---

## Krytyczne pliki do modyfikacji w toxo

| Plik | Zmiana |
|------|--------|
| `app/models/sample.rb` | Przepisać na `ApiModel::Base` |
| `app/models/measurement.rb` | Przepisać na `ApiModel::Base` (read-only) |
| `app/models/patient.rb` | Przepisać na `ApiModel::Base` |
| `app/models/project.rb` | Przepisać na `ApiModel::Base` |
| `app/models/reserved_sample_code.rb` | Przepisać na `ApiModel::Base` |
| `app/controllers/samples_controller.rb` | Usunąć transakcję AR, delegować do API |
| `app/controllers/application_controller.rb` | Usunąć Pundit include |
| `app/policies/sample_policy.rb` | Przenieść do API, usunąć z toxo |
| `Gemfile` | Dodać faraday, faraday-retry; usunąć pundit |

**Nowe pliki w toxo:**
- `app/models/api_model/base.rb`
- `app/models/api_model/connection.rb`
- `app/controllers/concerns/api_error_handling.rb`

**Zostają bez zmian:**
- `app/models/contractor.rb` (AR)
- `app/models/session.rb` (AR)
- `app/controllers/concerns/authentication.rb`
- `app/controllers/sessions_controller.rb`
- Wszystkie views (działają z `ActiveModel::Model` identycznie jak z AR)

---

## Część II: Implementacja zewnętrznego API (nowa aplikacja Rails)

### Routing w API

```ruby
# config/routes.rb (external API)
namespace :toxo, defaults: { format: :json } do
  namespace :samples do
    resources :registrations, only: %i[new index create destroy]
  end
end
```

Generuje:
- `GET  /toxo/samples/registrations`       → `Toxo::Samples::RegistrationsController#index`
- `GET  /toxo/samples/registrations/new`   → `Toxo::Samples::RegistrationsController#new`
- `POST /toxo/samples/registrations`       → `Toxo::Samples::RegistrationsController#create`
- `DELETE /toxo/samples/registrations/:id` → `Toxo::Samples::RegistrationsController#destroy`

### Struktura kontrolerów w API

```
app/controllers/
  toxo/
    base_controller.rb              ← Bearer token auth → current_contractor
    samples/
      registrations_controller.rb  ← CRUD + transakcja Sample+Measurements
```

**`Toxo::BaseController`:**
```ruby
class Toxo::BaseController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_by_token!

  private

  def authenticate_by_token!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    @current_session = Session.includes(:contractor).find_by(token: token)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_session
  end

  def current_contractor
    @current_session.contractor
  end

  alias_method :pundit_user, :current_contractor
end
```

**`Toxo::Samples::RegistrationsController#create`** — przenosi logikę z toxo `SamplesController#create`:
- Weryfikuje `authorize Sample` (Pundit: `can_add_samples?`)
- `project_ids |= [39] if project_ids.include?(40)`
- Sprawdza `wrong_registration`
- `ActiveRecord::Base.transaction` → Sample + N×Measurement
- Zwraca `201 Created` + sample JSON lub `422` + `{ errors: {...} }`

**`#index`:**
- `policy_scope(Sample)` z `current_contractor` jako `pundit_user`
- Zwraca JSON array przefiltrowanych samples

**`#new`:**
- Zwraca dane do formularza: lista aktywnych projektów (Id: 39, 40, 41, 42)

**`#destroy`:**
- `authorize @sample` (Pundit: `destroy?` = `deletable? && owner?`)
- Transakcja: `measurements.destroy_all` + `sample.destroy!`

### Modele w API (AR, pełna logika)

Przenoszone z toxo 1:1:
- `Sample < ApplicationRecord` z wszystkimi validations, callbacks, enums
- `Measurement < ApplicationRecord`
- `Patient`, `Project`, `ReservedSampleCode`, `Institution`
- `Contractor < ApplicationRecord` (read-only dla auth — bez `has_secure_password`)
- `Session < ApplicationRecord` (tylko `find_by(token:)` — weryfikacja tokena)

### Pundit w API

- `app/policies/sample_policy.rb` — przeniesiony z toxo bez zmian
- `Toxo::BaseController` includuje `Pundit::Authorization`, `pundit_user = current_contractor`
- `SamplePolicy::Scope` działa identycznie (AR join/union na tej samej MySQL)

### Serializacja JSON

Bez dodatkowych gemów:

```ruby
# 201 Created
render json: {
  Id: @sample.Id,
  Code: @sample.Code,
  MaterialType: @sample.MaterialType,
  dispatch_date: @sample.dispatch_date,
  Lot: @sample.Lot,
  Level: @sample.Level,
  AcceptanceDate: @sample.AcceptanceDate,
  IsWrongRegistration: @sample.IsWrongRegistration,
  WasWrongRegistration: @sample.WasWrongRegistration,
  measurements: @sample.measurements.map { |m|
    { Id: m.Id, ProjectId: m.ProjectId, Status: m.Status }
  }
}, status: :created

# 422 Unprocessable Entity
render json: { errors: @sample.errors.as_json }, status: :unprocessable_entity
```

### Endpoint mapping — toxo ↔ API

| Toxo `ApiModel` call | HTTP | API endpoint |
|----------------------|------|--------------|
| `Sample.all` | GET | `/toxo/samples/registrations` |
| `Sample.find(id)` | GET | `/toxo/samples/registrations/:id` |
| `Sample.new` / form data | GET | `/toxo/samples/registrations/new` |
| `@sample.save` (create) | POST | `/toxo/samples/registrations` |
| `@sample.destroy` | DELETE | `/toxo/samples/registrations/:id` |

---

## Weryfikacja (po implementacji)

**Po stronie API:**
1. `bin/rails test` — testy z AR fixtures
2. `POST /toxo/samples/registrations` z Bearer token → `201` + sample JSON
3. Błędny payload → `422` + `{ errors: { Code: ["not_in_pool"] } }`
4. Nieznany token → `401 Unauthorized`
5. Contractor bez `can_add_samples` → `403 Forbidden`

**Po stronie toxo (web app):**
1. `bin/rails test` — testy z WebMock stubami API
2. Rejestracja próbki end-to-end: formularz → toxo → API → MySQL → redirect z notice
3. `Sample.all` zwraca tylko próbki należące do zalogowanego contractora
4. Błędy walidacji z API (`422` + JSON) pojawiają się w formularzu
5. Usunięcie próbki: DELETE przez API → redirect z notice
6. Login/logout działa niezależnie od dostępności API
