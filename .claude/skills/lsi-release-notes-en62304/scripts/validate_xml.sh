#!/usr/bin/env bash
# Cross-platform "is this a well-formed XML file" check, used to sanity-check
# each hand-built OOXML part before zipping it into the .xlsx.
# Tries, in order: xmllint -> python3 (xml.dom.minidom) -> pwsh -> powershell.exe.
#
# Picks the tool ONCE by actually invoking it on a throwaway snippet, not just by
# checking `command -v` — on a stock Windows box `python3`/`python` on PATH is
# often a WindowsApps store stub that "exists" but fails with "Permission denied"
# on every invocation, which would otherwise silently break the fallback chain.
#
# Usage: validate_xml.sh <file> [<file> ...]
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: validate_xml.sh <file> [<file> ...]" >&2
  exit 1
fi

TOOL=""
if command -v xmllint >/dev/null 2>&1 && echo '<a/>' | xmllint --noout - >/dev/null 2>&1; then
  TOOL="xmllint"
elif command -v python3 >/dev/null 2>&1 && python3 -c "import xml.dom.minidom" >/dev/null 2>&1; then
  TOOL="python3"
elif command -v pwsh >/dev/null 2>&1 && pwsh -NoProfile -Command "1" >/dev/null 2>&1; then
  TOOL="pwsh"
elif command -v powershell.exe >/dev/null 2>&1 && powershell.exe -NoProfile -Command "1" >/dev/null 2>&1; then
  TOOL="powershell.exe"
else
  echo "validate_xml.sh: no working XML validator found (tried: xmllint, python3, pwsh, powershell.exe)" >&2
  exit 1
fi

check_one() {
  local f="$1"
  case "$TOOL" in
    xmllint)
      xmllint --noout "$f"
      ;;
    python3)
      python3 -c "import xml.dom.minidom, sys; xml.dom.minidom.parse(sys.argv[1])" "$f"
      ;;
    pwsh)
      pwsh -NoProfile -Command "[xml](Get-Content -LiteralPath '$f' -Encoding UTF8) | Out-Null"
      ;;
    powershell.exe)
      powershell.exe -NoProfile -Command "[xml](Get-Content -LiteralPath '$f' -Encoding UTF8) | Out-Null"
      ;;
  esac
}

status=0
for f in "$@"; do
  if check_one "$f"; then
    echo "OK: $f"
  else
    echo "FAIL: $f" >&2
    status=1
  fi
done
exit "$status"
