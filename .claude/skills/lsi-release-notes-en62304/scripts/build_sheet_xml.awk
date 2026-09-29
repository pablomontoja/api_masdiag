# Converts a pipe-delimited row file (one Markdown table row per line, e.g.
# "| col1 | col2 | col3 |") into a SpreadsheetML <worksheet> body using inline
# strings (no shared-strings table needed). Row 1 is the bold header row (style
# s="1"); data rows use style s="2" (top-aligned, wrapped text).
#
# Usage:
#   awk -v HEADERS="Col A|Col B|Col C" -v NCOLS=3 -f build_sheet_xml.awk rows.txt > sheet1.xml
#
# rows.txt: plain pipe-table rows WITHOUT the header/separator lines, e.g.
#   | abc123 (2026-01-01) | Did a thing | Kategoria | Niski |
#
# Column widths are fixed generic defaults; adjust the <cols> block below per use case.
function esc(s) {
  gsub(/&/, "\\&amp;", s)
  gsub(/</, "\\&lt;", s)
  gsub(/>/, "\\&gt;", s)
  return s
}
BEGIN {
  print "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
  print "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
  print "<sheetData>"
  n = split(HEADERS, harr, "|")
  print "<row r=\"1\">"
  for (i = 1; i <= n; i++) {
    col = sprintf("%c", 64 + i)
    printf "<c r=\"%s1\" s=\"1\" t=\"inlineStr\"><is><t xml:space=\"preserve\">%s</t></is></c>\n", col, esc(harr[i])
  }
  print "</row>"
  rownum = 2
}
{
  line = $0
  sub(/^\| */, "", line)
  sub(/ *\|$/, "", line)
  m = split(line, arr, "|")
  printf "<row r=\"%d\">\n", rownum
  for (i = 1; i <= m && i <= NCOLS; i++) {
    col = sprintf("%c", 64 + i)
    val = arr[i]
    gsub(/^ +| +$/, "", val)
    printf "<c r=\"%s%d\" s=\"2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">%s</t></is></c>\n", col, rownum, esc(val)
  }
  print "</row>"
  rownum++
}
END {
  print "</sheetData>"
  print "</worksheet>"
}
