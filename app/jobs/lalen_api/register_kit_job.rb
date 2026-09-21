module LalenApi
	class RegisterKitJob < ApplicationJob
		# Registers a kit with an external partner and retries on failure, so it must never
		# run for a write that was rolled back. See AssignKitTestsJob for why this is
		# declared per-job rather than globally.
		self.enqueue_after_transaction_commit = true

		retry_on StandardError, wait: :polynomially_longer, attempts: 10 do |job, error|
	    Sentry.capture_exception(error)
	  end

		def perform(sample)
			@sample = sample

	    begin
	      connection = LalenApi::Client.instance.connection
	      register_kit = LalenApi::RegisterKit.new(
	      																				barcode: @sample.Code, 
	      																				email: @sample.patient.email,
	      																				first_name: @sample.patient.FirstName,
	      																				last_name: @sample.patient.LastName,
	      																				birth_date: @sample.patient.BirthDate,
	      																				sample_collection_date: @sample.sample_collection_date,
	      																				gender: @sample.patient.Gender
	      																			)

	      if register_kit.valid?
	        response = connection.post('register_kit', register_kit.as_json, "Content-Type" => "application/json")
	      	pp response
	      	return if response.status == 404
	      	raise LalenApi::Error.new("Problems with Kit Registration on ApiMasdiagCom") if response.status != 201
        else
        	raise LalenApi::Error.new("Invalid RegisterKit for ApiMasdiagCom")
        end    

	      
	    rescue StandardError => e
	      Sentry.capture_exception(e)
	      raise e
	    end
		end
		
		
	end
end
