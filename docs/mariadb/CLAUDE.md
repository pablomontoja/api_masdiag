# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this directory is

This is **not application code** — it's a Docker Compose setup for a local MariaDB instance used to test
upgrading the database version that backs the Masdiag app fleet (see `~/.claude/CLAUDE.md` for the full
ecosystem context: LabSample database, the apps that share it, etc.).

The purpose of this environment is to work out, step by step, a safe upgrade path from the current
**MariaDB 10.1** (matching what's likely still running in production) to a modern supported version,
before that upgrade is ever attempted against production.

## Layout

- `docker-compose.yml` — defines two services: `db` (mariadb:10.1, container name `mariadb`) and
  `phpmyadmin` (phpmyadmin:latest). `db`'s datadir (`/var/lib/mysql`) is bind-mounted from `./database`.
- `./database/` — the live MariaDB datadir. Contains real database directories, notably `LabSample`
  (the shared production database), plus per-app databases such as `api_masdiag_staging`,
  `api_masdiag_test`, `intranetDB`, `masdiag_inspection`, `patient_portal`, `regspec`, `rejestracja2_test`,
  `toxo_dev_*`, `toxo_test`. Owned by `systemd-coredump`; most subdirectories are `root`-only and require
  elevated permissions to read directly from the host — go through the running container instead.
- `./conf.d/` — intended for custom MariaDB config (`my.cnf` includes), but the mount is currently
  **commented out** in `docker-compose.yml`, so anything placed here has no effect until that line is
  uncommented.
- `./tmp/` — bind-mounted into the container at `/tmp/db`.
- `./sessions/` — phpMyAdmin session storage (owned by `www-data`, i.e. written by the phpMyAdmin
  container, not meant to be edited by hand).

## Current running state (as observed, not defined by this compose file)

`docker ps` shows **two** parallel stacks alive on this host, only one of which corresponds to this
`docker-compose.yml`:

- `mariadb` / `phpmyadmin` — ports 3306 / 3080 — matches this directory's compose file.
- `mariadb2` / `phpmyadmin2` — ports 3307 / 3081 — **not defined here**; likely a second copy or an
  in-progress upgrade experiment living elsewhere. Confirm with the user which stack is the one under
  active upgrade work before assuming `mariadb`/3306 is authoritative.

Both `mariadb` containers currently report `mariadb Ver 15.1 Distrib 10.1.48-MariaDB`.

## Working on the upgrade

- Root credentials are commented out in `docker-compose.yml` (`MYSQL_ROOT_PASSWORD`, etc.) — the running
  container was presumably initialized before that was commented out. Do not add real credentials into
  this file; if env vars are needed, use a `.env` file (gitignored) and reference `${VAR}` as already
  scaffolded in the compose file's comments.
- MariaDB in-place upgrades must go through **each intermediate major version** (10.1 → 10.2 → 10.3 → ...),
  running `mysql_upgrade` after each version bump — you cannot jump straight to a modern release. Track
  the sequence of version bumps actually validated in this environment in a running log (e.g. append to
  this file or a dated log) so the same sequence can be replayed against production later.
- Before changing the image tag in `docker-compose.yml`, snapshot `./database` (it's just a directory —
  copy it) so a failed upgrade step can be rolled back without re-pulling a production backup.
- Since `LabSample` is shared production data (per the global Masdiag ecosystem rules), do not alter its
  schema here — this environment is for validating the *MariaDB engine* upgrade path, not for schema
  changes. Schema changes to shared LabSample tables still require explicit user confirmation per the
  global rules.
