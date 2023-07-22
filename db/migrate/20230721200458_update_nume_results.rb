class UpdateNumeResults < ActiveRecord::Migration[7.0]
  def change
    meases = Measurement.includes(sample: :patient).where(Patients: {ContractorId: 638}).where(ProjectId: 2)

    meases.each do |meas|
      newAnalyte = meas.result.analyte_results.find_by(AnalyteId: 310)
      next if !(newAnalyte.nil?)
      witD2425 = meas.result.analyte_results.find_by(AnalyteId: 83).Value
      witD3 = meas.result.analyte_results.find_by(AnalyteId: 80).Value

      res = witD2425 * 100 / witD3

      AnalyteResult.create(ResultId: meas.Id, AnalyteId: 310, Value: res, MeasuredValue: res, Unit: "%")
    end
  end
end
