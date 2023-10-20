class PatientPortal::Result
	include Rails.application.routes.url_helpers
	attr_reader :measurement_id, :sample_code, :authorization_date, :test_name, :url, :raw_result

	def initialize(measurement_id)		
		@measurement = Measurement.includes(sample: :patient).includes(:project).includes(:online_file).find(measurement_id)
		prepare()
	end

 private

 	def prepare
		@sample_code = @measurement.sample.Code
		@authorization_date = @measurement.AuthorizedAt
		@test_name = @measurement.project.Name
		@measurement_id = @measurement.Id

		if @measurement.online_file
			@measurement.online_file.prepare_active_storage()
			@url = url_for(@measurement.online_file.unencrypted_result)
		end
		
		@raw_result = RawResultResource.call(@measurement)
 	end
	
end