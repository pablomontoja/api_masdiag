# Znajduje Measurement (ProjectId=2), gdzie różnica pomiędzy
# sample.AcceptanceDate a measurement.AuthorizedAt jest większa niż 6 dni,
# ograniczone do Sample z AcceptanceDate > 2025-07-31.
# Wynik zapisywany jako CSV: sample.Code, sample.AcceptanceDate, measurement.AuthorizedAt

require "csv"

output_path = Rails.root.join("tmp", "measurements-authorization-delay.csv")

measurements = Measurement
  .joins(:sample)
  .where(ProjectId: 2)
  .where.not(AuthorizedAt: nil)
  .where("Samples.AcceptanceDate > ?", Date.new(2025, 7, 31))
  .where("DATEDIFF(Measurements.AuthorizedAt, Samples.AcceptanceDate) > ?", 6)
  .where.not("LENGTH(Samples.Code) = 6")
  .includes(:sample)

CSV.open(output_path, "w") do |csv|
  csv << ["Code", "AcceptanceDate", "AuthorizedAt"]

  measurements.find_each do |measurement|
    csv << [
      measurement.sample.Code,
      measurement.sample.AcceptanceDate,
      measurement.AuthorizedAt
    ]
  end
end

puts "Zapisano #{output_path}"
