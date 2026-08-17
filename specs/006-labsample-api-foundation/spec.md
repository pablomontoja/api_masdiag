# Feature Specification: Fundament API dla aplikacji laboratoryjnej

**Feature Branch**: `labsample3`

**Created**: 2026-08-14

**Status**: Draft

**Input**: Fundament pod przepisanie aplikacji LabSample — kontrola współbieżności,
uwierzytelnianie pracownika laboratorium i audyt zmian

## Kontekst

Aplikacja desktopowa laboratorium (`LabSample`) ma zostać stopniowo zastąpiona nową, która
komunikuje się wyłącznie z tym API. Przez okres przejściowy **obie aplikacje pracują równolegle
na tej samej bazie danych** — część pracowników w starej, część w nowej.

Ta funkcja buduje fundament, bez którego pierwszy moduł nowej aplikacji nie może powstać:
możliwość bezpiecznego jednoczesnego zapisu, rozpoznanie *którego pracownika* dotyczy żądanie,
oraz ślad audytowy każdej zmiany.

Analiza strategiczna, z której wynika ta funkcja: `labsample/specs/003-rewrite-strategy/strategy.md`.

**Dlaczego teraz**: dzisiejsza baza nie ma **żadnego** mechanizmu wykrywania konfliktów
(brak znaczników wersji, brak blokad). Dopóki pisze do niej jedna aplikacja, problem jest ukryty.
Z chwilą uruchomienia drugiej dwóch pracowników może po cichu nadpisać sobie zmiany —
w danych medycznych pacjentów.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ochrona przed cichym nadpisaniem zmian (Priority: P1)

Dwóch pracowników laboratorium otwiera ten sam rekord (np. projekt badawczy) i zapisuje zmiany
jeden po drugim. Dziś drugi zapis po cichu kasuje pracę pierwszego — nikt się o tym nie dowiaduje.
Pracownik potrzebuje informacji, że rekord zmienił się w międzyczasie, zamiast utraty danych.

**Why this priority**: To jedyne ryzyko w całym przedsięwzięciu, które może **niezauważenie
uszkodzić dane pacjentów**. Musi być rozwiązane, zanim powstanie pierwszy zapisujący moduł
nowej aplikacji. Bez tego cała reszta jest budowana na wadliwym fundamencie.

**Independent Test**: W pełni testowalne przez dwa równoległe żądania zmieniające ten sam rekord —
drugie musi zostać odrzucone z czytelną informacją, a nie przyjęte.

**Acceptance Scenarios**:

1. **Given** dwóch pracowników wczytało ten sam rekord, **When** obaj zapisują zmiany,
   **Then** pierwszy zapis się udaje, a drugi zostaje odrzucony z informacją o nieaktualnych danych.
2. **Given** pracownik wczytał rekord i nikt go nie zmienił, **When** zapisuje,
   **Then** zapis kończy się powodzeniem.
3. **Given** stara aplikacja zmieniła rekord bezpośrednio w bazie, **When** nowa aplikacja próbuje
   zapisać swoją wersję, **Then** konflikt zostaje wykryty.
4. **Given** odrzucony zapis, **When** pracownik odświeża dane, **Then** widzi aktualną wersję
   i może ponowić zmianę.

---

### User Story 2 - Logowanie pracownika laboratorium (Priority: P1)

Pracownik uruchamia nową aplikację i loguje się swoim dotychczasowym loginem i hasłem.
Nie zakłada nowego konta, nie zmienia hasła — używa tych samych poświadczeń co w starej aplikacji.

**Why this priority**: Bez rozpoznania pracownika nie istnieje audyt ani autoryzacja. Jest to też
warunek działania każdego kolejnego modułu. Równorzędny z US1, ale niezależny — można je
realizować równolegle.

**Independent Test**: Testowalne przez zalogowanie się istniejącym kontem pracownika i otrzymanie
ważnego dostępu, bez żadnej zmiany w tabeli użytkowników.

**Acceptance Scenarios**:

1. **Given** pracownik ma konto w systemie, **When** podaje poprawny login i hasło,
   **Then** otrzymuje dostęp do API bez konieczności resetu hasła.
2. **Given** pracownik podaje błędne hasło, **When** próbuje się zalogować, **Then** dostęp
   zostaje odmówiony bez informacji, który element był błędny.
3. **Given** konto pracownika jest nieaktywne, **When** próbuje się zalogować, **Then** dostęp
   zostaje odmówiony.
4. **Given** zalogowany pracownik, **When** wysyła żądanie do API, **Then** system rozpoznaje,
   który to pracownik.
5. **Given** klient partnerski korzystający z dotychczasowego sposobu dostępu, **When** wysyła
   żądanie, **Then** działa bez zmian.

---

### User Story 3 - Ślad audytowy każdej zmiany (Priority: P2)

Kierownik laboratorium musi móc ustalić, kto i kiedy zmienił dany rekord oraz co dokładnie
w nim zmienił. Dziś jest to praktycznie niemożliwe, bo zapisy z aplikacji desktopowej nie
zostawiają śladu.

**Why this priority**: To docelowa korzyść całego przedsięwzięcia. Wymaga jednak US2
(bez rozpoznania pracownika nie ma czego zapisać w śladzie), więc jest po niej.

**Independent Test**: Testowalne przez wykonanie zmiany przez API i sprawdzenie, że powstał wpis
wskazujący pracownika, czas, rodzaj operacji i zmienione wartości.

**Acceptance Scenarios**:

1. **Given** zalogowany pracownik, **When** tworzy, zmienia lub usuwa rekord przez API,
   **Then** powstaje wpis audytowy z jego tożsamością i wykazem zmienionych wartości.
2. **Given** kilka zmian tego samego rekordu, **When** przeglądamy historię, **Then** widoczna
   jest kolejność zmian.
3. **Given** różne typy kont (pracownik laboratorium, konto partnerskie), **When** każde z nich
   dokonuje zmiany, **Then** ślad rozpoznaje typ i tożsamość autora w jednolity sposób.

---

### User Story 4 - Wspólny mechanizm dostępu dla klientów wewnętrznych (Priority: P3)

Zespół utrzymujący API potrzebuje jednego, spójnego sposobu obsługi klientów działających
w imieniu zalogowanego użytkownika, zamiast osobnego rozwiązania dla każdej aplikacji.

**Why this priority**: Porządkuje i przygotowuje grunt pod kolejne moduły, ale nie blokuje
pierwszego z nich. Może powstać po US1–US3.

**Independent Test**: Testowalne przez sprawdzenie, że dotychczasowy klient portalowy i nowa
aplikacja korzystają z tego samego mechanizmu przechowywania dostępu, bez regresji.

**Acceptance Scenarios**:

1. **Given** istniejący klient portalowy, **When** korzysta z API po zmianie, **Then** działa
   dokładnie jak wcześniej.
2. **Given** dwa różne typy klientów, **When** oba uzyskują dostęp, **Then** korzystają z jednego
   wspólnego mechanizmu.

---

### Edge Cases

- Co się dzieje, gdy stara aplikacja zmieni rekord **pomijając** mechanizm wersjonowania
  (pisze wprost do bazy)? Konflikt musi zostać wykryty mimo to.
- Co z rekordami istniejącymi przed wprowadzeniem znacznika wersji — jak są traktowane
  przy pierwszym zapisie?
- Co, gdy dane w bazie nie spełniają dzisiejszych reguł poprawności (stara aplikacja je omijała)?
  Odczyt takich rekordów musi być możliwy, nawet jeśli zapis wymaga poprawy.
- Co się dzieje z dostępem pracownika po dłuższej nieaktywności?
- Jak zachowuje się system, gdy ten sam pracownik pracuje na dwóch stanowiskach naraz?
- Co, gdy pracownik zmieni hasło w starej aplikacji — czy dostęp w nowej pozostaje ważny?

## Requirements *(mandatory)*

### Functional Requirements

**Kontrola współbieżności**

- **FR-001**: System MUSI wykrywać próbę zapisu rekordu, który zmienił się od momentu jego odczytu.
- **FR-002**: Wykryty konflikt MUSI skutkować odrzuceniem zapisu i czytelną informacją, a nigdy
  cichym nadpisaniem.
- **FR-003**: Wykrywanie MUSI działać również wtedy, gdy zmiana pochodzi ze starej aplikacji
  piszącej bezpośrednio do bazy.
- **FR-004**: Rekordy istniejące przed wdrożeniem mechanizmu MUSZĄ pozostać zapisywalne.

**Uwierzytelnianie**

- **FR-005**: Pracownik MUSI móc uzyskać dostęp, podając dotychczasowe poświadczenia —
  **bez resetowania hasła**.
- **FR-005a**: System MUSI akceptować poświadczenia w **obu** dotychczasowych formatach:
  tym używanym przez panel webowy oraz tym używanym przez aplikację desktopową. Format panelu
  webowego ma pierwszeństwo, gdy pracownik ma oba.
- **FR-005b**: Docelowym, jedynym formatem MUSI być format panelu webowego (standard pozostałych
  aplikacji). Wycofanie formatu desktopowego następuje po wygaszeniu aplikacji desktopowej
  i jest **poza zakresem tej funkcji**.
- **FR-006**: System MUSI odmówić dostępu przy błędnych poświadczeniach oraz kontu nieaktywnym,
  nie ujawniając, który element zawiódł.
- **FR-007**: Każde żądanie od zalogowanego pracownika MUSI być powiązane z jego tożsamością.
- **FR-008**: Dotychczasowe sposoby dostępu (klienci partnerscy, portal) MUSZĄ działać bez zmian.
- **FR-009**: Dostęp MUSI dać się unieważnić (wylogowanie).

**Audyt**

- **FR-010**: Utworzenie, zmiana i usunięcie rekordu przez API MUSZĄ zostawiać ślad audytowy.
- **FR-011**: Ślad MUSI zawierać tożsamość autora, czas, rodzaj operacji i zmienione wartości.
- **FR-012**: Ślad MUSI rozpoznawać różne typy autorów (pracownik laboratorium, konto partnerskie)
  w jednolity sposób.
- **FR-013**: Kolejność zmian tego samego rekordu MUSI być odtwarzalna.

**Wspólny mechanizm dostępu**

- **FR-014**: Klienci działający w imieniu zalogowanego użytkownika MUSZĄ korzystać ze wspólnego
  mechanizmu przechowywania dostępu, niezależnie od typu użytkownika.
- **FR-015**: Zmiana mechanizmu NIE MOŻE naruszyć działania istniejących klientów.

### Key Entities

- **Pracownik laboratorium**: osoba obsługująca system; ma login, hasło, rolę i status aktywności.
  Istnieje już w systemie — funkcja go nie tworzy.
- **Dostęp (sesja)**: powiązanie przyznanego dostępu z użytkownikiem; obecnie obsługuje tylko
  jeden typ użytkownika, docelowo dowolny.
- **Tożsamość autora**: jednolite wskazanie „kto wykonał zmianę", niezależne od typu konta.
- **Wpis audytowy**: zapis pojedynczej zmiany — co, kto, kiedy, jakie wartości.
- **Znacznik wersji rekordu**: informacja pozwalająca stwierdzić, czy rekord zmienił się
  od momentu odczytu.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: W scenariuszu jednoczesnej edycji tego samego rekordu przez dwie osoby liczba cichych
  utrat zmian wynosi **zero** — drugi zapis zawsze kończy się czytelną odmową.
- **SC-002**: **100%** pracowników loguje się dotychczasowymi poświadczeniami; liczba resetów
  haseł wymuszonych wdrożeniem wynosi **zero**. Dotyczy zarówno pracowników korzystających
  z panelu webowego, jak i wyłącznie z aplikacji desktopowej.
- **SC-002a**: Pracownik mający konto w panelu webowym loguje się do nowej aplikacji **tym samym
  hasłem** co do panelu — liczba haseł do zapamiętania spada z dwóch do jednego.
- **SC-003**: Dla **każdej** zmiany dokonanej przez API da się wskazać autora, czas i zakres zmiany.
- **SC-004**: Czas ustalenia „kto zmienił ten rekord" spada z „praktycznie niewykonalne"
  do pojedynczego zapytania.
- **SC-005**: Wszyscy dotychczasowi klienci API działają bez zmian — **zero** regresji.
- **SC-006**: Pierwszy moduł nowej aplikacji może powstać bez dodatkowych prac fundamentowych.

## Assumptions

- Hasła pracowników są zapisane w sposób umożliwiający weryfikację po stronie API bez ich resetu;
  ustalono to przy analizie i potwierdzono zgodność obu algorytmów.
- Tabela użytkowników zawiera **dwa równoległe zestawy pól uwierzytelniających** — jeden używany
  przez aplikację desktopową, drugi przez panel webowy. Ten sam pracownik ma dziś dwa niezależne
  hasła. Funkcja akceptuje oba formaty; ujednolicenie do jednego następuje po wygaszeniu
  aplikacji desktopowej.
- Tabela śladu audytowego **już istnieje** w bazie z kompletnym układem kolumn, ale nie jest przez
  nic używana — funkcja ją aktywuje, zamiast tworzyć od nowa.
- Mechanizm dostępu obecnie obsługuje jeden typ użytkownika; rozszerzenie na dowolny typ zostało
  uzgodnione wcześniej jako kierunek docelowy.
- Kontrola współbieżności obejmuje w pierwszej kolejności rekordy edytowane przez pierwszy moduł
  nowej aplikacji; rozszerzanie na kolejne tabele następuje wraz z kolejnymi modułami.
- Obsługa kart kryptograficznych pozostaje po stronie aplikacji klienckiej; do API trafia wyłącznie
  wynik uwierzytelnienia.
- Zakres nie obejmuje żadnego modułu funkcjonalnego (projekty, próbki, wyniki) — wyłącznie fundament.

## Dependencies

- Analiza strategiczna: `labsample/specs/003-rewrite-strategy/strategy.md`
- Dokument architektoniczny: `plans/004-labsample-to-api.md`
- Karta pierwszego modułu: `labsample/specs/003-rewrite-strategy/modules/01-projects.md`

## Out of Scope

- Jakikolwiek moduł funkcjonalny nowej aplikacji (projekty, próbki, płytki, wyniki, protokoły).
- Sama aplikacja kliencka — jej powstanie jest przedmiotem osobnej pracy.
- Migracja generowania dokumentów wynikowych.
- Wycofanie dotychczasowych sposobów uwierzytelniania.
- Obsługa kart kryptograficznych po stronie API.
