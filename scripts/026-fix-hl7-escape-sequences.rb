# Fixes Hl7Import records where kit_code_extracted contains HL7 escape sequences
# (e.g. "17CJUV\X0D0A\") that were imported before the strip_hl7_escapes fix.
# Also clears the stale error_message and resets status to :pending so the
# PendingImportLinker can re-attempt matching.
#
# Run with: bin/rails runner scripts/026-fix-hl7-escape-sequences.rb

affected = Hl7Import.where("kit_code_extracted LIKE ?", "%\\\\%")

puts "Found #{affected.count} Hl7Import records with escape sequences in kit_code_extracted"

affected.find_each do |import|
  clean_code = import.kit_code_extracted.gsub(/\\[^\\]+\\/, "")

  puts "  [#{import.id}] #{import.kit_code_extracted.inspect} → #{clean_code.inspect}"

  import.update!(
    kit_code_extracted: clean_code,
    error_message:      nil,
    status:             :pending
  )
end

puts "Done. #{affected.count} records updated."
