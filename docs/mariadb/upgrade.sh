#!/usr/bin/env bash
#
# Automates MariaDB major-version hops (X.Y -> X.(Y+1) -> ... -> X.Z) via docker
# compose: bumps the image tag, recreates the container, streams startup logs,
# runs mysql_upgrade, verifies version/databases, restarts and checks logs again.
# Asks for confirmation before each hop and on any detected problem.
#
# Designed to run identically against this local test stack and later against
# production (same docker-compose based setup) — see --from/--to and --skip-backup.
#
# Usage:
#   ./upgrade.sh --from 10.8 --to 10.11 [--skip-backup] [--yes]
#   ./upgrade.sh --from 10.1 --to 10.11              # full production chain, with backups

set -euo pipefail

COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="db"
CONTAINER_NAME="mariadb"
DATADIR="$COMPOSE_DIR/database"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

SKIP_BACKUP=false
ASSUME_YES=false
FROM_VERSION=""
TO_VERSION=""

RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

log()  { printf '%s[*] %s%s\n' "$BLUE" "$*" "$NC"; }
ok()   { printf '%s[OK] %s%s\n' "$GREEN" "$*" "$NC"; }
warn() { printf '%s[!] %s%s\n' "$YELLOW" "$*" "$NC" >&2; }
err()  { printf '%s[ERROR] %s%s\n' "$RED" "$*" "$NC" >&2; }

confirm() {
    local prompt="$1"
    if [ "$ASSUME_YES" = true ]; then
        return 0
    fi
    local reply
    read -r -p "$prompt [y/N] " reply
    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

require_confirm_or_exit() {
    local prompt="$1"
    if ! confirm "$prompt"; then
        err "Przerwano przez użytkownika."
        exit 1
    fi
}

usage() {
    cat <<EOF
Użycie: $0 --from X.Y --to X.Z [--skip-backup] [--yes]

  --from VERSION    Wersja startowa (np. 10.8) — musi zgadzać się z aktualnym
                     tagiem obrazu w docker-compose.yml
  --to VERSION       Wersja docelowa (np. 10.11)
  --skip-backup      Pomiń backup datadira przed każdym hopem (użyj lokalnie,
                     gdy brak miejsca na dysku na kopię) — NIE zalecane na produkcji.
                     Backup jest robiony przed każdym hopem, a poprzedni backup jest
                     usuwany dopiero PO potwierdzeniu, że bieżący hop jest stabilny
                     (weryfikacja + restart bez błędów) — w danym momencie istnieje
                     więc zawsze co najwyżej jedna kopia datadira.
  --yes               Pomiń wszystkie prompty potwierdzenia (nienadzorowany przebieg;
                     backup poprzedniego hopu też usuwany automatycznie bez pytania)
  -h, --help          Ten opis
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --from) FROM_VERSION="$2"; shift 2 ;;
        --to) TO_VERSION="$2"; shift 2 ;;
        --skip-backup) SKIP_BACKUP=true; shift ;;
        --yes) ASSUME_YES=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) err "Nieznany argument: $1"; usage; exit 1 ;;
    esac
done

if [ -z "$FROM_VERSION" ] || [ -z "$TO_VERSION" ]; then
    err "Wymagane --from i --to."
    usage
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    err "Nie znaleziono $COMPOSE_FILE"
    exit 1
fi

compose() {
    docker compose -f "$COMPOSE_FILE" "$@"
}

current_version() {
    grep -oP 'image:\s*mariadb:\K[0-9]+\.[0-9]+' "$COMPOSE_FILE" | head -1
}

bump_image() {
    local new_version="$1"
    sed -i -E "s/(image:\s*mariadb:)[0-9]+\.[0-9]+/\1${new_version}/" "$COMPOSE_FILE"
}

# Generates the list of minor-version hops from FROM_VERSION (exclusive) to TO_VERSION
# (inclusive), assuming the MariaDB 10.x series (major stays 10, minor increments by 1).
generate_hops() {
    local from="$1" to="$2"
    local from_minor to_minor
    from_minor="${from#10.}"
    to_minor="${to#10.}"
    if [ "$from_minor" = "$from" ] || [ "$to_minor" = "$to" ]; then
        err "Skrypt obsługuje tylko serię 10.x (np. 10.8, 10.11). Otrzymano: $from -> $to"
        exit 1
    fi
    if [ "$from_minor" -ge "$to_minor" ]; then
        err "--from ($from) musi być mniejsze niż --to ($to)"
        exit 1
    fi
    local minor=$((from_minor + 1))
    while [ "$minor" -le "$to_minor" ]; do
        echo "10.$((minor - 1)) 10.$minor"
        minor=$((minor + 1))
    done
}

PREVIOUS_BACKUP=""
CURRENT_BACKUP=""

backup_datadir() {
    local version="$1"
    if [ "$SKIP_BACKUP" = true ]; then
        warn "Backup pominięty (--skip-backup)."
        return 0
    fi
    local dest="${DATADIR}.bak-${version}-$(date +%Y%m%d-%H%M%S)"
    log "Backup datadira przed hopem z ${version}: $dest"
    compose stop "$SERVICE_NAME"
    cp -a "$DATADIR" "$dest"
    compose start "$SERVICE_NAME"
    ok "Backup zapisany: $dest"
    CURRENT_BACKUP="$dest"
}

# Usuwa backup z POPRZEDNIEGO hopu dopiero po tym, jak bieżący hop przeszedł pełną
# weryfikację (verify + restart_and_check) — nigdy nie usuwa backupu bieżącego hopu,
# więc zawsze istnieje punkt przywrócenia dla ostatniego wykonanego kroku.
cleanup_previous_backup() {
    if [ "$SKIP_BACKUP" = true ] || [ -z "$PREVIOUS_BACKUP" ]; then
        return 0
    fi
    if [ ! -d "$PREVIOUS_BACKUP" ]; then
        return 0
    fi
    require_confirm_or_exit "Hop stabilny — usunąć poprzedni backup ($PREVIOUS_BACKUP)?"
    log "Usuwam poprzedni backup: $PREVIOUS_BACKUP"
    rm -rf "$PREVIOUS_BACKUP"
    ok "Usunięto: $PREVIOUS_BACKUP"
}

pull_and_up() {
    log "Pobieranie nowego obrazu i restart kontenera..."
    compose pull "$SERVICE_NAME"
    compose up -d "$SERVICE_NAME"
}

# Streams container logs until "ready for connections" appears or timeout hits,
# so the operator watches the real startup output rather than a static tail.
stream_startup_logs() {
    log "Logi startowe kontenera (do 'ready for connections' lub 20s):"
    local deadline=$((SECONDS + 20))
    docker logs -f "$CONTAINER_NAME" 2>&1 &
    local log_pid=$!
    while [ $SECONDS -lt $deadline ]; do
        if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "ready for connections"; then
            break
        fi
        sleep 1
    done
    sleep 1
    kill "$log_pid" 2>/dev/null || true
    wait "$log_pid" 2>/dev/null || true

    if docker logs "$CONTAINER_NAME" 2>&1 | tail -50 | grep -q "\[ERROR\]"; then
        warn "W logach startowych znaleziono [ERROR] (może być znany błąd typu"
        warn "mysql.event po majorowym skoku — naprawi go mysql_upgrade w kolejnym kroku)."
        docker logs "$CONTAINER_NAME" 2>&1 | tail -50 | grep "\[ERROR\]" || true
        require_confirm_or_exit "Kontynuować mimo błędów w logach startowych?"
    fi
}

run_mysql_upgrade() {
    log "Uruchamiam mysql_upgrade..."
    if compose exec -T -e MYSQL_PWD="$ROOT_PASSWORD" "$SERVICE_NAME" mysql_upgrade -u root; then
        ok "mysql_upgrade zakończony sukcesem."
    else
        err "mysql_upgrade zwrócił błąd."
        require_confirm_or_exit "Przerwać cały skrypt? (odpowiedz 'y' aby przerwać teraz — Ctrl+C przerywa zawsze)"
        err "Zatrzymuję dalsze hopy."
        exit 1
    fi
}

verify() {
    log "Weryfikacja wersji i listy baz danych:"
    compose exec -T -e MYSQL_PWD="$ROOT_PASSWORD" "$SERVICE_NAME" \
        mysql -u root -e "SELECT VERSION(); SHOW DATABASES;"
    require_confirm_or_exit "Wersja i lista baz wyglądają poprawnie — kontynuować?"
}

restart_and_check() {
    log "Restart kontenera i sprawdzenie logów po restarcie..."
    compose restart "$SERVICE_NAME"
    sleep 3
    docker logs "$CONTAINER_NAME" 2>&1 | tail -30
    if docker logs "$CONTAINER_NAME" 2>&1 | tail -30 | grep -q "\[ERROR\]"; then
        warn "Po restarcie w logach nadal są błędy [ERROR]:"
        docker logs "$CONTAINER_NAME" 2>&1 | tail -30 | grep "\[ERROR\]" || true
        require_confirm_or_exit "Kontynuować mimo to?"
    else
        ok "Restart czysty, brak [ERROR] w logach."
    fi
}

main() {
    local actual_current
    actual_current="$(current_version)"
    if [ "$actual_current" != "$FROM_VERSION" ]; then
        err "Aktualny obraz w docker-compose.yml to mariadb:${actual_current}, nie ${FROM_VERSION}."
        err "Popraw --from albo docker-compose.yml przed uruchomieniem."
        exit 1
    fi

    local hops
    hops="$(generate_hops "$FROM_VERSION" "$TO_VERSION")"
    log "Zaplanowane hopy:"
    echo "$hops" | while read -r f t; do echo "  $f -> $t"; done

    require_confirm_or_exit "Rozpocząć sekwencję upgrade'ów ${FROM_VERSION} -> ${TO_VERSION}?"

    read -r -s -p "Hasło roota MariaDB: " ROOT_PASSWORD
    echo
    export ROOT_PASSWORD

    while read -r -u 9 from_v to_v; do
        echo
        echo "=================================================="
        echo " Hop: ${from_v} -> ${to_v}"
        echo "=================================================="
        require_confirm_or_exit "Rozpocząć hop ${from_v} -> ${to_v}?"

        backup_datadir "$from_v"
        bump_image "$to_v"
        pull_and_up
        stream_startup_logs
        run_mysql_upgrade
        verify
        restart_and_check

        cleanup_previous_backup
        PREVIOUS_BACKUP="$CURRENT_BACKUP"

        ok "Hop ${from_v} -> ${to_v} zakończony."
    done 9<<< "$hops"

    if [ "$SKIP_BACKUP" != true ] && [ -n "$PREVIOUS_BACKUP" ] && [ -d "$PREVIOUS_BACKUP" ]; then
        warn "Backup z ostatniego hopu pozostaje na dysku (punkt przywrócenia): $PREVIOUS_BACKUP"
        warn "Usuń go ręcznie po potwierdzeniu długoterminowej stabilności."
    fi

    echo
    ok "Wszystkie hopy zakończone. Wersja końcowa:"
    compose exec -T -e MYSQL_PWD="$ROOT_PASSWORD" "$SERVICE_NAME" mysql -u root -e "SELECT VERSION();"
    warn "Pamiętaj: skrypt NIE dopisuje wpisów do README.md — zrób to ręcznie,"
    warn "zachowując dotychczasowy format (data, wynik, ewentualne uwagi 'Ważne dla produkcji')."
}

main
