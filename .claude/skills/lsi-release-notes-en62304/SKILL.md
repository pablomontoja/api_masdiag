---
name: "lsi-release-notes-en62304"
description: "Produce a tabular, compliance-oriented changelog (Markdown + xlsx) between two git commits, with per-commit category and EN 62304 patient-safety-impact assessment, plus an optional short 'Opis wydania' release-reason summary. Use when asked for a change/audit log, or a release-notes cover summary, between two commits or tags for a medical-device or regulated codebase."
argument-hint: "<from-commit> <to-commit> [output-language, default: pl]"
metadata:
  author: "session-derived"
  source: "distilled from an interactive session building this exact deliverable for LabSample"
user-invocable: true
disable-model-invocation: false
---

## Purpose

Given two git commit hashes (or tags), produce a deliverable that a QA/RA person can hand to an auditor:

1. A **main table** — one row per included commit — with columns: `Hash git / Data`, `Opis zmian` (short change summary), `Kategoria` (1-3 tags from a closed list), `Wpływ na bezpieczeństwo pacjenta (EN 62304)` (closed 5-level scale + one-line justification).
2. A short, separate **"najważniejsze zmiany" / highlights table** (2 columns: `Obszar zmiany`, `Opis zmiany`) picking out the handful of changes that actually matter for a reviewer skimming the release.
3. Both as a **Markdown file** and a **.xlsx workbook** (2 sheets), even on machines with no Python/openpyxl available.
4. On request (typically once the table above already exists, or when the user frames the range as "one release") — a very short, general-audience **"Opis wydania" (release-reason summary)**: 4-7 bullet points explaining *why* the release happened, not what changed line-by-line. See step 7.

This skill was distilled from a real run: LabSample (WPF/.NET laboratory sample management system), range `d18c53f..721f259`, 134 raw commits → 120 rows after filtering, split into 4 parallel-fork batches of 30, ~3 minutes wall-clock for categorization once the plan was set.

## Defaults (override only if the user specifies otherwise)

- **Output language**: Polish (labels, descriptions, category names) — this reflects the regulatory-document convention of this project. If the user asks for the deliverable in another language, translate the category list and impact scale consistently, but keep the standard closed set of categories (do not invent new ones per language).
- **Category list (closed, 1-3 per commit)**: `Zmiana frontend`, `Zmiana backend`, `Nowa funkcjonalność`, `Drobna korekta`, `Poprawka backendu`, `Poprawka frontendu`, `Zmiana administracyjna (wersjonowanie)`, `Hotfix`, `Zmiana infrastruktury`, `Bezpieczeństwo`, `Build`.
- **Impact scale (closed, 1 per commit + short justification)**: `Pozytywny wpływ` / `Brak wpływu` / `Niski` / `Średni` / `Wysoki`. Lab/medical-device software skews toward the low end — most changes should land on "Pozytywny wpływ", "Brak wpływu" or "Niski"; reserve "Wysoki" for changes that could plausibly have caused a wrong result to reach a patient/clinician.
- **Excluded commits**: pure `Merge branch ...` commits and commits whose *entire* subject is a bare version bump (e.g. `v2.9.9.19`) are dropped from the table — they carry no reviewable content. A version-bump commit that also carries a description (e.g. `v2.9.9-rc1-hf6 - AldxReportStrategy result rounding fix`) is KEPT and categorized on its actual content, with `Zmiana administracyjna (wersjonowanie)` as one of its categories.
- **Row granularity**: one row per commit, not per logical feature — even if that means many small "migrate X to i18n"-style rows.

If any of the above is ambiguous for the current request (different category taxonomy wanted, different exclusion rule, single vs. dual output format), ask the user with `AskUserQuestion` before starting the batch work — don't guess on things that reshape the whole deliverable.

## Procedure

### 1. Scope the commit range

```
git log --pretty=format:'%h|%ad|%s' --date=short --no-merges <from>..<to>
```

Filter out commits whose subject is *purely* a version string (regex like `^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9]+)*\s*$`) — inspect the list manually rather than trusting the regex blindly, some "version" commits carry a real description after the version token (see Defaults above). Save the final, chronologically-ordered list to a scratch file, one `hash|date|subject` per line.

Count the rows. If the range is small (~20 commits or fewer), just do the categorization yourself inline — don't bother with parallel forks for that. The forking strategy below only pays off once you're past ~40-50 commits.

### 2. Pre-fetch diff stats once, for everyone

```
git show --stat --format="=== <hash> <date> <subject> ===" <hash> >> stats.txt
```
for every included commit, into one shared scratch file. This lets every downstream worker (or yourself) see file-level scope without re-running git per commit, and is cheap enough to do for the whole range up front.

### 3. Categorize in parallel batches (for large ranges)

Split the chronological commit list into batches of ~25-30 commits (4 batches worked well for 120 commits). For each batch, launch a `fork` (not a fresh general-purpose agent — it inherits your context, e.g. the category list and impact-scale wording, without you having to re-explain project domain) with a self-contained prompt that includes:

- The exact batch commit-list file path and the shared `stats.txt` path.
- The full category list and impact-scale wording verbatim (copy from Defaults above, translated if needed) — do NOT let each fork improvise its own scale, or the batches won't cohere.
- Explicit instruction: rely on subject + `git show --stat`; only pull a full `git show <hash> -- <file>` diff when the commit plausibly touches result calculation, import/export, analyte/patient matching, or PDF report generation and the subject/stat alone doesn't make the safety call obvious.
- The exact output contract: write ONLY the Markdown table fragment (header + separator + N rows, nothing else) to a named scratch file, plus an optional highlights-table fragment to a second named file.
- A reminder that the batch must cover every commit in its input file — no skipping.

Launch all batch forks in **one message, multiple tool calls** — they're independent. Do not poll; wait for the task-notifications. This is the expensive/slow part of the whole skill (each batch took ~2-3 minutes and ~120k tokens in the reference run) — parallelizing it is the entire point of forking.

### 4. Assemble

Once all batches report back, concatenate their table fragments in chronological order under one header, and their highlights fragments under a second 2-column table. Sanity-check the row count: `grep -c '^| [a-f0-9]'` on the assembled table should equal the number of commits you started with in step 1. Spot-check 2-3 rows tagged "Średni"/"Wysoki" for plausibility before delivering.

Write the assembled Markdown to a deliverable file with a title, a one-paragraph scope note (range, excluded-commit count and reason), the main table, then the highlights table.

### 5. Build the .xlsx (no Python required — works on Windows and Linux)

Check first whether a usable Python + `openpyxl` is available (`python3 -c "import openpyxl"`, and on Windows also try `py -c "import openpyxl"` — see Pitfalls); if so, that's simpler — write a short script instead of the manual route. If not, hand-build the workbook as raw OOXML using the bundled `scripts/` helpers, all POSIX `sh`/`awk` except one Windows-only fallback:

1. `bash scripts/scaffold_xlsx.sh <build_dir> "<Sheet1 name>" "<Sheet2 name>"` — writes `[Content_Types].xml`, both `_rels`, `workbook.xml`, `styles.xml`.
2. For each sheet, strip the Markdown table down to bare `| ... | ... |` data rows (no header/separator lines) into a rows file, then:
   `awk -v HEADERS="Col A|Col B|..." -v NCOLS=<n> -f scripts/build_sheet_xml.awk rows.txt > <build_dir>/xl/worksheets/sheet1.xml`
   (repeat for sheet2 with its own headers/NCOLS).
3. Validate every XML part is well-formed before zipping: `bash scripts/validate_xml.sh <build_dir>/**/*.xml "<build_dir>/[Content_Types].xml"`. It tries `xmllint` → `python3`'s `xml.dom.minidom` → `pwsh` → `powershell.exe`, whichever is present, so it doesn't matter which platform you're on.
4. Zip it: `bash scripts/build_xlsx.sh <build_dir> <output.xlsx>`. Same fallback chain: `zip` → `python3 zipfile` → `pwsh` → `powershell.exe` (the last one shelling out to `scripts/build_xlsx.ps1`, kept only as that final Windows-without-anything-else fallback — don't call the `.ps1` directly, always go through `build_xlsx.sh` so the script picks the right tool for the current box).
5. Re-open the result and list entries as a final structural sanity check (7 entries: the 4 listed above + 2 worksheet parts + the workbook rels) — `unzip -l <output.xlsx>` if `unzip` is available, otherwise `python3 -c "import zipfile,sys; print(zipfile.ZipFile(sys.argv[1]).namelist())" <output.xlsx>`.

Cell styling used: `s="1"` = bold white-on-blue header row, `s="2"` = top-aligned wrapped-text body cell. Column widths are hardcoded in the awk script's `<cols>` block — adjust per table shape (the reference run used 22/55/28/45 for the 4-column main sheet and 30/70 for the 2-column highlights sheet).

### 6. Deliver

Send both files with `SendUserFile`. In the chat reply, give: final row count vs. raw commit count (and why they differ), the impact-scale distribution (a quick `grep -oE` tally over the assembled Markdown works), and call out anything tagged "Średni"/"Wysoki" that deserves a human second look — don't just hand over the files silently.

### 7. Release-reason summary ("Opis wydania")

Only produce this when asked (or when the user explicitly frames the whole commit range as "one release" and wants a cover-note summary). It is a *different altitude* than the main table: not a list of changes, but the handful of underlying drivers that explain why a release happened at all. Follow the house template exactly — it's a fixed prior-art format, don't restructure it:

```
Wydanie obejmuje zmiany akumulowane od <miesiąc rozpoczęcia zakresu, słownie, np. "czerwca 2024 r."> we wszystkich <N/czterech/...> komponentach systemu. Główne powody wydania to:
    • <driver 1>,
    • <driver 2>,
    • ...
    • <driver N>.
```

How to derive it without re-reading every commit:

1. Start date = the date of the first included commit from step 1 (month + year, Polish genitive form, e.g. "września 2024 r.").
2. Component count = however many top-level app/service components the range actually touched (check against the project's own architecture doc, e.g. this repo's `CLAUDE.md` three-layer breakdown) — say "we wszystkich N komponentach" only if true, don't default to "czterech" if the range only touched two.
3. Bullets = cluster the **highlights table** from step 4 (and, if it's thin, skim the main table's `Kategoria`/`Opis zmian` columns) into 4-7 *causal* groups, each one clause, no commit hashes, no file names. Typical recurring clusters seen in practice: expansion of the clinical-report-strategy library, changes to a specific external-platform integration (name it), an architecture/platform migration, accumulated bugfixes from production use, infrastructure/dependency upgrades, customer-mandated changes. Order roughly by weight (biggest driver first), bugfixes and administrative/infra items last.
4. Keep each bullet to one line, noun-phrase style (not full sentences) — mirror the tone of: "rozbudowa biblioteki raportów klinicznych o nowe strategie raportowania", "korekty błędów zgłoszonych w trakcie eksploatacji". Do not add a justification or EN 62304 rating here — that belongs in the main table, not this summary.
5. Present it as a draft and ask the user whether the length/granularity matches their target (they may want it trimmed to exactly 5 bullets to match a prior release's format) rather than treating your first cut as final — this is a house style document other releases will be compared against, so match cadence over completeness.

## Pitfalls hit in the reference run (avoid repeating)

- `ScheduleWakeup` is a `/loop`-only tool — don't reach for it just to "wait" for fork notifications; they arrive as task-notifications on their own. Stop any wakeup you accidentally scheduled.
- PowerShell's sandbox pattern-matcher can misfire on an unrelated line (e.g. a `-replace '\','/'` call got flagged as if it were `Remove-Item` on a suspicious path) purely from adjacent script text. If a command is blocked for a reason that doesn't match what it does, rewrite the offending line (e.g. swap `-replace` literal backslash for `[regex]::Escape('\')`) rather than assuming the action itself is unsafe. This only matters if you end up on the `build_xlsx.ps1` fallback path at all — on Linux, or on Windows with `zip`/`python3` present, `build_xlsx.sh` never touches PowerShell.
- `python`/`python3` on a stock Windows dev box can resolve to the WindowsApps stub and fail with "Permission denied" even though `python.exe` "exists" on PATH — don't waste time debugging that stub; just check `py -c "import openpyxl"` too, and let `scripts/build_xlsx.sh` / `scripts/validate_xml.sh` fall through to the next tool on their own rather than hand-rolling the same fallback logic inline.
- The `scripts/*.sh` files need the executable bit on a fresh checkout of this skill on Linux/macOS (`chmod +x scripts/*.sh`) — Windows doesn't track it, so a `git clone` from a Windows-authored commit can land with it unset. Prefer invoking them as `bash scripts/build_xlsx.sh ...` (works either way) over relying on `./scripts/build_xlsx.sh` being directly executable.
