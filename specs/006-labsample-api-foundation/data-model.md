# Phase 1: Data Model — Fundament API

**Feature**: 006-labsample-api-foundation | **Date**: 2026-08-14

---

## Nowe byty

### `Person` — jednolita tożsamość autora

Tabela `people` (**do utworzenia**):

| Kolumna | Typ | Uwagi |
|---|---|---|
| `id` | bigint PK | |
| `personable_type` | string, NOT NULL | `"User"` / `"ApiAccount"` |
| `personable_id` | bigint, NOT NULL | |
| `created_at`, `updated_at` | datetime, NOT NULL | |

Indeks: `[personable_type, personable_id]` — unikalny (jedna tożsamość na konto).

```ruby
class Person < ApplicationRecord
  audited
  belongs_to :personable, polymorphic: true
  validates :personable_id, uniqueness: { scope: :personable_type }

  def fullname = personable&.fullname
end
```

**Uwaga**: `User.Id` jest typu `integer` (tabela C#), więc `personable_id` musi to pomieścić —
`bigint` jest bezpieczny. Nie kopiować UUID-owej wersji z `masdiag_com`.

### `Personable` — concern

```ruby
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

Włączają: `User`, `ApiAccount`.

**Backfill wymagany**: `Users` i `ApiAccounts` już zawierają rekordy. Bez utworzenia dla nich
`Person` walidacja `required: true` odrzuci pierwszy zapis istniejącego pracownika.
Osobne zadanie migracyjne.

---

## Byty zmieniane

### `Session` — polimorficzny właściciel

| Zmiana | Przed | Po |
|---|---|---|
| Właściciel | `contractor_id` integer NOT NULL | `owner_type` string + `owner_id` bigint |
| Indeks | `[contractor_id]` | `[owner_type, owner_id]` |
| Token | `token` unikalny | bez zmian |

```ruby
class Session < ApplicationRecord
  belongs_to :owner, polymorphic: true
  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end
```

Migracja: dodać kolumny → backfill (`owner_type = "Contractor"`, `owner_id = contractor_id`)
→ indeks → `contractor_id` **zostawić** do czasu potwierdzenia braku regresji.

`Toxo::BaseController#current_contractor` musi działać bez zmian (`@current_session.owner`).

### `User` — pracownik laboratorium

Tabela `Users` (C#, PascalCase) — **bez zmian w schemacie**. Zmiany wyłącznie w modelu:

```ruby
class User < ApplicationRecord
  include Personable
  self.table_name = "Users"
  self.primary_key = "Id"
  self.inheritance_column = :_type_bla_bla   # istniejący obejść dla kolumny `type`

  def authenticate(password)  # weryfikacja PBKDF2 — patrz research R1
  def active? = self.IsActive
end
```

**Tabela `Users` zawiera dwa równoległe systemy uwierzytelniania** (research R1a):

| Zestaw | Kolumny | Używa |
|---|---|---|
| C# / PBKDF2 | `Login`, `Password`, `Salt` | LabSample (desktop) |
| Devise / bcrypt | `email`, `encrypted_password`, `reset_password_token`, `reset_password_sent_at`, `remember_created_at`, `sign_in_count`, `current_sign_in_at`, `last_sign_in_at`, `current_sign_in_ip`, `last_sign_in_ip`, `password_changed_at`, `type` | `labpanel` |

Pozostałe kolumny istotne: `IsActive`, `Role`, `FirstName`, `LastName`,
`LastPasswordChangeAt`, `PasswordChangeRevokedAt`, `HasSmartCard`, `LastSelectedCertLabel`.

**Uwaga o `type`**: kolumna istnieje dla STI Devise, ale api_masdiag ją neutralizuje
(`self.inheritance_column = :_type_bla_bla`) — tak samo robią `labpanel` i `indclients2`.
Nie zmieniać tego zachowania.

**Kolejność weryfikacji hasła** (FR-005a): `encrypted_password` → PBKDF2. Zapisu haseł
ta funkcja nie obejmuje.

### `ApiAccount`

Dodanie `include Personable`. Reszta bez zmian — musi działać dla wszystkich istniejących
namespace'ów (FR-008).

### `Project` — pierwszy model objęty kontrolą i audytem

| Zmiana | Rodzaj |
|---|---|
| `lock_version` integer, default 0, NOT NULL | **migracja** |
| znacznik `ON UPDATE CURRENT_TIMESTAMP` | **migracja** — kształt do rozstrzygnięcia (research R2) |
| `audited` w modelu | kod |

```ruby
class Project < ApplicationRecord
  audited
  self.table_name = "Projects"
  self.primary_key = "Id"
  self.locking_column = "lock_version"
end
```

**Ostrzeżenie**: encja C# `Project` ma 16 pól i nie zna żadnej z tych kolumn. EF wykona
`UPDATE` bez nich — dlatego znacznik musi być sterowany przez bazę, nie przez aplikację.

### `Current` — kontekst żądania

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :api_account   # istniejący
  attribute :lab_user      # NOWY
end
```

---

## Reguły walidacyjne

| # | Reguła | Źródło |
|---|---|---|
| V1 | Hasło weryfikowane PBKDF2-HMAC-SHA1, 10 000 iteracji, 64 B, base64 | FR-005 |
| V2 | Porównanie hasła w czasie stałym (`secure_compare`) | FR-006 |
| V3 | Konto nieaktywne (`IsActive = false`) → odmowa | FR-006 |
| V4 | Odmowa nie ujawnia, czy zawiódł login czy hasło | FR-006 |
| V5 | Każde konto ma dokładnie jedną tożsamość `Person` | FR-012 |
| V6 | Zapis z nieaktualnym `lock_version` → odrzucenie | FR-001, FR-002 |
| V7 | Zapis z nieaktualnym znacznikiem → odrzucenie | FR-003 |
| V8 | Rekordy sprzed migracji pozostają zapisywalne (`default: 0`) | FR-004 |

---

## Przepływ zapisu z kontrolą współbieżności

```text
Klient                          API                         MySQL
  │  GET /projects/:id           │                            │
  │─────────────────────────────►│  SELECT                    │
  │                              │───────────────────────────►│
  │  { Id, ..., lock_version,    │                            │
  │    updated_marker }          │                            │
  │◄─────────────────────────────│                            │
  │                              │                            │
  │  PATCH + lock_version        │                            │
  │       + updated_marker       │                            │
  │─────────────────────────────►│                            │
  │                              │ 1. znacznik zgodny?        │
  │                              │    (wykrywa zapis z EF)    │
  │                              │ 2. UPDATE ... WHERE        │
  │                              │    lock_version = ?        │
  │                              │───────────────────────────►│
  │  409 Conflict  ◄── konflikt  │                            │
  │  200 OK        ◄── sukces    │                            │
```

Dwa sygnały pełnią różne role: `lock_version` wychwytuje konflikt między dwoma klientami API,
znacznik bazodanowy — zapis z aplikacji desktopowej, która o obu kolumnach nie wie.
