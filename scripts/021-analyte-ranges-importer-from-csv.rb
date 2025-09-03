require 'csv'

io = File.open('tmp/analyte-ranges.csv', 'r')
csv = CSV.new(io, headers: true, header_converters: :symbol, col_sep: ";")
analyte_ranges = csv.to_a.map {|row| row.to_hash }



analyte_ranges.each do |a|
puts %Q(
original_analyte = Analyte.where(ProjectId: 3).find_by\(Name: "#{a[:mq_name]}"\)
analyte = original_analyte.dup
analyte.assign_attributes\(CutoffMin: #{a[:cutoff_min]}, CutoffMax: #{a[:cutoff_max]}, material_type: 10\)
analyte.save!

men_analyte_range = AnalyteRange.create!\(
  Name: "Mężczyzna",
  AgeFrom: 0,
  AgeTo: 150,
  Gender: 0,
  Min: #{a[:ref_min]},
  Max: #{a[:ref_max]},
  AnalyteId: analyte.Id,
  AgeFromMonth: 0,
  AgeToMonth: 0,
  AgeFromInMonths: 0,
  AgeToInMonths: 1800,
  Multiplier: 1.0,
  AcceptableMin: #{a[:ref_min]},
  AcceptableMax: #{a[:ref_max]}
\)

women_analyte_range = AnalyteRange.create!(
  Name: "Kobieta",
  AgeFrom: 0,
  AgeTo: 150,
  Gender: 1,
  Min: #{a[:ref_min]},
  Max: #{a[:ref_max]},
  AnalyteId: analyte.Id,
  AgeFromMonth: 0,
  AgeToMonth: 0,
  AgeFromInMonths: 0,
  AgeToInMonths: 1800,
  Multiplier: 1.0,
  AcceptableMin: #{a[:ref_min]},
  AcceptableMax: #{a[:ref_max]}
)
)
end