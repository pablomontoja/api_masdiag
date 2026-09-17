# Runbook: raporty i eksporty

> Zapytania i skrypty eksportowe uruchamiane z konsoli Rails. Tylko do odczytu —
> nie modyfikują danych, ale potrafią być ciężkie (limit 10 000 rekordów w eksporcie CSV).

## Pomiary nieujęte w measurement summaries
```ruby
Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["Hospital", "ForeignInstitution"] }}}}).where(Status: 5, AuthorizedAt: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")



Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["ForeignInstitution"] }}}}).where(Status: 4, MeasureDate: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")
```

## Eksport wyników wg instytucji i projektu
```ruby
require "csv"
INST_ID = 128 # ORKLA
PROJECTID = 34

def extract_result_row(res)
	res.analyte_results.sort_by{|ar| ar.AnalyteId}.map { |ar| ar.Value  }
end

def sex(gender)
	return "M" if gender == 0
	return "K" if gender == 1
end

codes = ReservedSampleCode.where(InstitutionId: INST_ID).pluck(:Code)

r_ids = Result.includes(:measurement).includes(measurement: :sample).where(measurement: {Samples: {IsControlSample: false, Code: codes}}).where(Measurements: { ProjectId: PROJECTID, Status: [4, 5] }).order(MeasurementId: :desc).limit(10000).pluck(:MeasurementId)


CSV.open("tmp/aa-result-export-2.csv", "wb") do |csv|
	header = []
	header << "Kod"
	header << "Imię"
	header << "Nazwisko"
	header << "PESEL"
	header << "Płeć"
	header << "Data wydania"
	header << "Data urodzenia"
	header << "Data pobrania"
	header << "Wyjście z magazynu"

	header = header + Result.includes(:analyte_results).where(MeasurementId: r_ids).first.analyte_results.sort_by{|ar| ar.AnalyteId}.map { |ar| ar.analyte.Name  }

	pp header

	csv << header

	Result.includes(:analyte_results).includes(measurement: {sample: :patient}).where(MeasurementId: r_ids).find_in_batches(batch_size: 1000) do |group|	  
	  group.each do |res|
	  	pat = res.measurement.sample.patient 
	  	csv << [res.measurement.sample.Code, pat.FirstName, pat.LastName, pat.Pesel, sex(pat.Gender), res.measurement.AuthorizedAt&.strftime("%F"), pat.BirthDate&.strftime("%F"), res.measurement.sample.sample_collection_date&.strftime("%F"), res.measurement.sample.rsc&.package&.stock_room_item&.date_out&.strftime("%F")] + extract_result_row(res)
	  end
	end

end



```

## Walidacja LSI (IEC 62304)

As part of the validation of the LSI Masdiag software in accordance with IEC 62304, it is necessary to prepare a software configuration report with each software release.
A script has been created that prepares the data needed to prepare the report.

To run validation script please use the following command:
```bash
rails runner LSI_validation.rb
```

### PROMPTS

`git log --pretty=format:"%h - %an, %cd : %s" b2079cbfecd32fc1b1702f040bc399d43e5eca46..6ef70b987fd7c4847ba6166988edd3508d6994e3
List all commits from dd68a0a9afb614e9bf484af6d848121379752c1d to d18c53fadbc8f40e1209f1cf72e9524bed3944d1.
Check all above git commits and gather info about changes across all commits between the specified range.
Finally create a table with a git hash (including the commit date in the same column beow the hash), a description of the changes, the category of changes (minor correction, security correction, backend change, frontend change, hotfixes, and so on), and the impact of the changes on patient safety (in the context of EN 62304)? Please use markdown format and translate content to Polish language. Order by by commit date, ascending.`

