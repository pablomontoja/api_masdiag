#!/usr/bin/env bash
# Cross-platform zip of a folder of hand-built OOXML parts into a .xlsx file.
# Tries, in order: zip -> python3 (zipfile) -> pwsh (PowerShell Core) -> powershell.exe
# (Windows PowerShell) -> so it works unmodified on a bare Linux box (zip/python3
# are almost always present) and on a bare Windows box (only powershell.exe present,
# as was the case in the reference run this skill was built from).
#
# Usage: build_xlsx.sh <build_dir> <output.xlsx>
set -euo pipefail

SRC="$1"
DEST="$2"

if [ ! -d "$SRC" ]; then
  echo "build_xlsx.sh: source dir not found: $SRC" >&2
  exit 1
fi

DEST_DIR="$(cd "$(dirname "$DEST")" && pwd)"
DEST_ABS="$DEST_DIR/$(basename "$DEST")"
rm -f "$DEST_ABS"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v zip >/dev/null 2>&1; then
  ( cd "$SRC" && zip -X -q -r "$DEST_ABS" . )

elif command -v python3 >/dev/null 2>&1 && python3 -c "import zipfile" >/dev/null 2>&1; then
  python3 - "$SRC" "$DEST_ABS" <<'PY'
import sys, os, zipfile
src, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(src):
        for name in files:
            full = os.path.join(root, name)
            rel = os.path.relpath(full, src)
            zf.write(full, rel)
PY

elif command -v pwsh >/dev/null 2>&1 && pwsh -NoProfile -Command "1" >/dev/null 2>&1; then
  pwsh -NoProfile -File "$SCRIPT_DIR/build_xlsx.ps1" -Src "$SRC" -Dest "$DEST_ABS" >/dev/null

elif command -v powershell.exe >/dev/null 2>&1 && powershell.exe -NoProfile -Command "1" >/dev/null 2>&1; then
  powershell.exe -NoProfile -File "$SCRIPT_DIR/build_xlsx.ps1" -Src "$SRC" -Dest "$DEST_ABS" >/dev/null

else
  echo "build_xlsx.sh: no zip tool found (need one of: zip, python3, pwsh, powershell.exe)" >&2
  exit 1
fi

echo "Created: $DEST_ABS"
