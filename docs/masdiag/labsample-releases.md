# Wydania LabSample.Updater (`LabsampleRelease`)

## Przegląd

`LabsampleRelease` (`app/models/labsample_release.rb`) reprezentuje pojedyncze wydanie
instalatora aplikacji desktopowej **LabSample** (`../labsample`, C# WPF), dystrybuowanego
jako archiwum `.7z`. Aplikacja desktopowa (a konkretnie jej moduł `LabSample.Updater`)
odpytuje dwa endpointy w namespace `masdiag` przed każdym uruchomieniem okna logowania,
żeby sprawdzić, czy dostępna jest nowsza wersja, i pobrać jej instalator.

```
LabSample.Updater --(GET /masdiag/labsample/latest_version)--> API sprawdza najnowszy rekord
LabSample.Updater --(GET /masdiag/labsample/download_url)-----> API zwraca URL do pliku .7z
```

## Model (`app/models/labsample_release.rb`)

```ruby
class LabsampleRelease < ApplicationRecord
  has_one_attached :archive

  def self.latest
    order(:created_at).last
  end
end
```

- Tabela `labsample_releases` (migracja `db/migrate/20260918140000_create_labsample_releases.rb`)
  — **własna tabela tej aplikacji**, nie należy do współdzielonej bazy LabSample w sensie
  tabel z konwencją C# (`Id`/PascalCase) — używa standardowych konwencji Rails.
  Kolumny: `version` (string, `null: false`, unikalny indeks), `created_at`, `updated_at`.
- `archive` — plik `.7z` instalatora, dołączony przez **Active Storage**
  (`has_one_attached`), przechowywany w MinIO w produkcji (patrz `CLAUDE.md` → File Storage).
  Nie ma osobnej kolumny na ścieżkę pliku — to Active Storage zarządza powiązaniem
  blob/attachment.
- `LabsampleRelease.latest` — najnowszy rekord po `created_at` (nie po numerze wersji;
  zakłada, że rekordy są dodawane w kolejności chronologicznej odpowiadającej kolejności
  wydań).

## Dodawanie nowego wydania — task `labsample_releases:add`

Nowe wydanie dodaje się przez rake task (`lib/tasks/labsample_releases.rake`), podając
numer wersji i lokalną ścieżkę do pliku `.7z`:

```bash
rvm use 3.4.10
bin/rails "labsample_releases:add[2.9.11.10,/path/to/labsample-2.9.11.10.7z]"
```

Task (`labsample_releases:add`):

1. Waliduje, że oba argumenty (`version`, `archive_path`) są podane — inaczej `abort`
   z komunikatem użycia.
2. Waliduje, że plik pod `archive_path` istnieje (`File.exist?`) — inaczej `abort`.
3. Waliduje rozszerzenie `.7z` (case-insensitive) — inaczej `abort`.
4. Sprawdza unikalność wersji (`LabsampleRelease.exists?(version:)`, zgodnie z unikalnym
   indeksem w bazie) — przy duplikacie `abort` bez tworzenia rekordu.
5. Tworzy `LabsampleRelease` i dołącza plik przez `archive.attach(io:, filename:)`.

`abort` kończy proces z niezerowym kodem wyjścia i komunikatem na stderr/stdout — task
jest pomyślany do uruchamiania ręcznie przez operatora (np. po zbudowaniu nowej wersji
instalatora), nie jako część automatycznego pipeline'u CI.

Pokrycie testowe: `spec/lib/tasks/labsample_releases_rake_spec.rb` (tworzenie rekordu
z załącznikiem, `abort` przy duplikacie wersji, przy braku pliku, przy złym rozszerzeniu).

## Endpointy (`app/controllers/masdiag/labsample_controller.rb`)

Trasy w `config/routes.rb` (blok `namespace :masdiag, defaults: {format: :json}`):

```ruby
get "labsample/latest_version", to: "labsample#latest_version"
get "labsample/download_url",   to: "labsample#download_url"
```

| Route | Akcja | Zachowanie | Odpowiedź |
|---|---|---|---|
| `GET /masdiag/labsample/latest_version` | `#latest_version` | `LabsampleRelease.latest&.version` | `200 {"version": "2.9.11.10"}` lub `200 {"version": null}`, gdy brak rekordów |
| `GET /masdiag/labsample/download_url` | `#download_url` | gdy brak rekordu lub brak dołączonego pliku → `{url: nil}`; w innym wypadku `rails_blob_url(release.archive, host: request.base_url)` | `200 {"url": "https://.../rails/active_storage/blobs/.../labsample-....7z"}` lub `200 {"url": null}` |

### Autoryzacja — uwaga

W odróżnieniu od pozostałych czterech kontrolerów namespace'u `masdiag`,
`Masdiag::LabsampleController` **nie** dołącza `MasdiagCheck` — chroniony jest wyłącznie
standardowym HTTP Basic z `ApplicationController#authenticate` (dowolne aktywne
`ApiAccount`, bez wymogu `institution.id == 1`). Zamierzone: LabSample.Updater loguje się
danymi zwykłego konta API instytucji, a nie konta instytucji Masdiag.

### Brak walidacji wersji po stronie klienta

Endpoint `latest_version` jedynie **zwraca** numer najnowszej wersji — porównanie z
aktualnie zainstalowaną wersją i decyzja o aktualizacji leżą całkowicie po stronie
aplikacji desktopowej LabSample.Updater, nie tej aplikacji.

## Testy

- `spec/lib/tasks/labsample_releases_rake_spec.rb` — pokrywa task `labsample_releases:add`
  (patrz wyżej).
- `spec/factories/labsample_release_factory.rb` — fabryka FactoryBot (`version` domyślnie
  `"2.9.11.10"`, bez domyślnie dołączonego archiwum).
- **Brak** request speca dla samego `Masdiag::LabsampleController` (`latest_version`,
  `download_url`) — luka w pokryciu, patrz `docs/masdiag/README.md` → "Braki w pokryciu".
