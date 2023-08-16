meases = Measurement.where(Status: 5, ProjectId: [2,3,10,12,14]).order(Id: :desc)
user = User.first

ActiveRecord::Base.transaction do
	meases.each do |meas|
		meas.result&.destroy
		result = Result.create(MeasurementId: meas.Id, ImportDate: Time.now - 14.days, IsValid: true, ImportUserId: user.Id)

		meas.project.analytes.where(is_required: true).each do |analyte|
			fake_value = Faker::Number.within(range: 0.0..100.0)
			fake_value = Faker::Number.within(range: analyte.CutoffMin..analyte.CutoffMax) if !analyte.CutoffMin.nil? && !analyte.CutoffMax.nil?
			result.analyte_results.create(AnalyteId: analyte.Id, Value: fake_value, Unit: analyte.Unit, MeasuredValue: fake_value)
		end
	end
end