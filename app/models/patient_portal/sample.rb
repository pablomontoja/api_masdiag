class PatientPortal::Sample
	include Rails.application.routes.url_helpers
	attr_reader :sample_id, :code, :acceptance_date, :tests_to_do, :status

	def initialize(sample_id)
		@sample_id = sample_id	
		@sample = Sample.find(@sample_id)
		prepare()
	end

 private

 	def prepare
		@code = @sample.Code
		@acceptance_date = @sample.AcceptanceDate
		@tests_to_do = @sample.measurements.where(Status: [1, 2, 3, 4, 7]).map{|m| m.project.Name}.join(", ")
		[4,5].include?(@sample.soaking_degree_id) ? @status = "cancelled" : @status = nil
 	end
	
end