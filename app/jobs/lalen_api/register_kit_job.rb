module LalenApi
	class RegisterKitJob < ApplicationJob
		retry_on StandardError, wait: :exponentially_longer, attempts: 10 do |job, error|
	    errors = [Time.current.to_s, "module LalenApi", job.class.name, "Exception - #{error}", "Job details: #{job.to_json}"]
	    puts errors
	    # IndMailer.after_error(errors).deliver_later
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

	      
	    rescue Faraday::Error => e
	      err = ["body: #{e.inspect}"]
	      pp(err)
	      raise e
	    end
		end
		
		
	end
end
