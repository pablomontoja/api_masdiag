# System powiadomień e‑mail — specyfikacja zdarzeń

Dokument źródłowy: opis przepływu obsługi próbek w laboratorium toksykologicznym Masdiag.
Cel: lista zdarzeń wywołujących wysyłkę wiadomości e‑mail wraz z warunkami i treściami,
do implementacji systemu powiadomień w aplikacji Ruby on Rails.

Portal Partnera / rejestracji: `toxo.masdiag.pl`
Oprogramowanie laboratoryjne: `LabSample` - korzysta z endpointów /masdiag i /masdiag_mailer

---

## Przepływ (skrót)

```
Rejestracja próbki (formularz)  ──►  [A] Potwierdzenie zlecenia (e-mail + PDF)
                │
                ▼
    Odbiór / dostawa próbki do laboratorium
                │
        ┌───────┴────────────────────────────┐
   próbka                              próbka NIE
zarejestrowana                        zarejestrowana
        │                                    │
   ┌────┴─────┐                     [C] Przypomnienie o rejestracji (1)
   │          │                              │
[B] Przyjęcie  [E] Odrzucenie      po 7 dniach roboczych bez rejestracji
do badań      próbki                        │
   │                              [D] Przypomnienie powtórne (2)
   ▼                                         │
Badanie                          dalszy brak rejestracji → ZWROT próbki
   │                              (protokół odesłania — dokument fizyczny,
   ▼                               bez e-maila)
[F] Wynik badania
   │
   ▼
Postępowanie po badaniu: archiwizacja / utylizacja / zwrot
(protokoły fizyczne, poza systemem — bez e-maila)
```

---

## Zdarzenia wywołujące e‑mail

Sześć zdarzeń. Kolumna **Typ wyzwalacza** rozróżnia zdarzenia sterowane stanem
(callback / zmiana statusu) od sterowanych czasem (zadanie w tle / harmonogram).

| # | Klucz zdarzenia | Nazwa (PL) | Typ wyzwalacza | Warunek |
|---|---|---|---|---|
| A | `order_confirmation` | Potwierdzenie zlecenia badania | zdarzenie (rejestracja) | Zleceniodawca wypełnił i wysłał formularz rejestracji próbki |
| B | `sample_accepted` | Potwierdzenie przyjęcia próbki do badań | zdarzenie (przyjęcie) | Próbka dotarła do laboratorium i została zakwalifikowana do badania |
| C | `registration_reminder` | Przypomnienie o konieczności rejestracji próbki | zdarzenie (dostawa) | Próbka dotarła do laboratorium, ale nie jest zarejestrowana |
| D | `registration_reminder_final` | Przypomnienie powtórne o konieczności rejestracji | czas (harmonogram) | Upłynęło 7 dni roboczych od dostawy, próbka nadal niezarejestrowana |
| E | `sample_rejected` | Odrzucenie próbki zleconej do badań | zdarzenie (dyskwalifikacja) | Próbka dotarła, ale nie została zakwalifikowana do badania |
| F | `result_available` | Wynik badania | zdarzenie (publikacja wyniku) | Sprawozdanie z badań dostępne w systemie dla Partnerów |

> **Uwaga o zwrocie próbki:** brak rejestracji w terminie do 7 dni roboczych od
> drugiego przypomnienia skutkuje odesłaniem próbki na koszt Zleceniodawcy.
> Zwrot dokumentowany jest **protokołem odesłania** (kopia fizyczna w przesyłce +
> kopia do archiwum) — **nie generuje e‑maila**. Analogicznie postępowanie po
> badaniu (archiwizacja / utylizacja / zwrot) to protokoły fizyczne poza systemem
> fakturowym i również nie wysyła powiadomień.

---

## Treści wiadomości

Zmienne oznaczone `{{ ... }}`. `{{sample_number}}` odpowiada `XXXX` z dokumentu
źródłowego. Wszystkie treści w języku polskim (odbiorcy — Zleceniodawcy w PL).

### A. `order_confirmation` — Potwierdzenie zlecenia badania (rejestracja próbki w systemie, podobne powiadomienie już jest wysyłane przez system laboratoryjny w kontekście próbek diagnostyki laboratoryjnej - IndMailer.after_sample_registration)
- **Kanał:** e‑mail + załącznik PDF
- **Załącznik:** PDF z podsumowaniem wszystkich danych z formularza rejestracji próbki
- **Temat:** `Potwierdzenie zlecenia badania`
- **Treść:**
  ```
  Szanowni Państwo,

  Potwierdzamy przyjęcie zlecenia badania. W załączeniu znajduje się
  podsumowanie zarejestrowanego zlecenia w formacie PDF.
  ```
  > Treść e‑maila nie jest podana wprost w dokumencie źródłowym — powyższe to
  > propozycja. Kluczowy jest sam fakt: e‑mail z załączonym PDF‑em zawierającym
  > wszystkie dane z formularza rejestracji.

### B. `sample_accepted` — Potwierdzenie przyjęcia próbki do badań (podobny mailer w obecnym systemie: SendAcceptanceNotificationsMailer)
- **Temat:** `Potwierdzenie przyjęcia próbki do badań`
- **Treść:**
  ```
  Szanowni Państwo,

  Informujemy, że próbka {{sample_number}} dotarła do laboratorium
  i została zakwalifikowana do badania.
  ```

### C. `registration_reminder` — Przypomnienie o konieczności rejestracji próbki (brak odpowiednika w obecnym systemie)
- **Temat:** `Przypomnienie o konieczności rejestracji próbki`
- **Treść:**
  ```
  Szanowni Państwo,

  Informujemy, że próbka o numerze {{sample_number}} została dostarczona
  do laboratorium. Przypominamy o konieczności rejestracji w celu zlecenia
  badania.

  Rejestracja badania odbywa się w systemie toxo.masdiag.pl
  ```

### D. `registration_reminder_final` — Przypomnienie powtórne o konieczności rejestracji próbki (brak odpowiednika w obecnym systemie)
- **Temat:** `Przypomnienie powtórne o konieczności rejestracji próbki`
- **Treść:**
  ```
  Szanowni Państwo,

  Informujemy, że próbka o numerze {{sample_number}} została dostarczona
  do laboratorium. Przypominamy ponownie o konieczności rejestracji w celu
  zlecenia badania.

  Rejestracja badania odbywa się w systemie toxo.masdiag.pl

  W przypadku niezarejestrowania próbki w terminie do 7 dni roboczych
  próbka zostanie odesłana na koszt Zleceniodawcy.
  ```

### E. `sample_rejected` — Odrzucenie próbki zleconej do badań (podobny mailer w obecnym systemie: SendCancellationNotificationsMailer)
- **Temat:** `Odrzucenie próbki zleconej do badań`
- **Treść:**
  ```
  Szanowni Państwo,

  Informujemy, że próbka dotarła do laboratorium i nie została
  zakwalifikowana do badania.
  ```
- **Dane próbki do zawarcia w wiadomości** (pola z dokumentu):
  - Kod próbki — `{{sample_code}}`
  - Numer próbki (pakietu) — `{{sample_number}}`
  - Numer wewnętrzny klienta — `{{client_internal_number}}`
  - Typ materiału — `{{material_type}}`
  - Zlecone badania — `{{ordered_tests}}`
  - Tryb (CITO / Standard) — `{{mode}}`

### F. `result_available` — Wynik badania (podobny mailer w obecnym systemie: ContractorResultNotificationMailer)
- **Temat:** `Wynik badania`
- **Treść:**
  ```
  Szanowni Państwo,

  Informujemy, że wynik dla próbki o numerze {{sample_number}} jest dostępny.
  Sprawozdanie z badań znajduje się w systemie informatycznym dla Partnerów
  (toxo.masdiag.pl).
  ```

---

## Zmienne szablonów (referencja)

| Zmienna | Opis | Występuje w |
|---|---|---|
| `{{sample_code}}` | Kod próbki (prefix 2 znaki + `_` + 5 znaków, np. `MD_12345`) | E |
| `{{sample_number}}` | Numer próbki / pakietu (pole tekstowe do 15 znaków) — `XXXX` w dokumencie | B, C, D, E, F |
| `{{client_internal_number}}` | Numer wewnętrzny klienta (opcjonalny, do 15 znaków) | E |
| `{{material_type}}` | Rodzaj materiału (krew pełna / mocz / płyn z gałki ocznej / osocze‑surowica / ocieklina) | E |
| `{{ordered_tests}}` | Zlecone badania (zakres usług) | E |
| `{{mode}}` | Tryb realizacji: CITO / Standard | E |
| `{{partner_portal_url}}` | `toxo.masdiag.pl` | C, D, F |

---

## Sugerowana struktura w Rails

### Mailer

```ruby
# app/mailers/sample_notification_mailer.rb
class SampleNotificationMailer < ApplicationMailer
  def order_confirmation(sample)          # A — dołącza PDF z podsumowaniem zlecenia
  def sample_accepted(sample)             # B
  def registration_reminder(sample)       # C
  def registration_reminder_final(sample) # D
  def sample_rejected(sample)             # E
  def result_available(sample)            # F
end
```

### Wyzwalanie

Zdarzenia sterowane stanem — najlepiej na przejściach maszyny stanów próbki
(np. `after_commit` / hook przejścia stanu), nie w kontrolerze:

- `order_confirmation` — po utworzeniu/wysłaniu rejestracji (submit formularza).
- `sample_accepted` — przy przejściu do stanu „zakwalifikowana do badania".
- `registration_reminder` — przy zarejestrowaniu dostawy próbki niepowiązanej z rejestracją.
- `sample_rejected` — przy przejściu do stanu „odrzucona / niezakwalifikowana".
- `result_available` — przy publikacji sprawozdania.

Zdarzenia sterowane czasem — zadanie w tle uruchamiane cyklicznie:

- `registration_reminder_final` — job (np. codzienny) wybierający próbki dostarczone,
  niezarejestrowane, dla których minęło **7 dni roboczych** od dostawy; liczenie
  dni roboczych (z pominięciem weekendów/świąt) po stronie serwisu, nie w mailerze.
- (opcjonalnie) job egzekwujący **zwrot** próbki po kolejnych 7 dniach roboczych
  bez rejestracji — generuje protokół odesłania, **nie e‑mail**.

### Proponowane stany cyklu życia próbki

```
registered → delivered → accepted → in_testing → result_available
                  │           │
                  │           └─► rejected
                  └─► (brak rejestracji) → reminded → reminded_final → returned
```

Powiadomienia (A–F) mapują się na wejścia do odpowiednich stanów; stany `returned`,
`archived`, `disposed` nie wysyłają e‑maili (tylko protokoły fizyczne).

---

## Uwagi implementacyjne

1. **Idempotencja:** każde powiadomienie wysyłać dokładnie raz na próbkę/zdarzenie —
   warto prowadzić log wysłanych powiadomień (np. tabela `sample_notifications`
   z unikalnym indeksem `(sample_id, kind)`), aby uniknąć duplikatów przy retry jobów.
2. **Dni robocze:** terminy (7 dni roboczych, a także SLA realizacji 2/3/5 dni CITO
   i 10/15 dni standard) liczone od daty przyjścia próbki do laboratorium — potrzebny
   kalendarz dni roboczych z obsługą świąt.
3. **Odbiorca:** adres e‑mail „osoby odpowiedzialnej za rejestrację" z konta
   użytkownika/firmowego Partnera.
4. **Dane wrażliwe:** pola `sample_number` i `client_internal_number` z założenia
   nie zawierają danych wrażliwych — treści e‑maili mogą je zawierać bezpiecznie.
5. **PDF (zdarzenie A):** generowany z danych formularza rejestracji i dołączany
   jako załącznik; ta sama zawartość co potwierdzenie zlecenia.
6. **Treść zdarzenia A** nie jest podana wprost w dokumencie — do uzgodnienia;
   pozostałe treści (B–F) pochodzą bezpośrednio z dokumentu źródłowego
   (drobne literówki poprawione).