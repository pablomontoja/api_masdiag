module Cerascreen
	module Labordatenbank
		class GetResultSvc < ApplicationService
			
		  def initialize(sample_code)
		    @sample_code = sample_code
		    @connection = Cerascreen::LabordatenbankClient.instance.connection
		  end
			
			def call
				begin
					resp = @connection.get("#{Rails.application.credentials.labordatenbank_api.url}/#{@sample_code}")
					return nil if resp.body.nil?

					r = Cerascreen::Labordatenbank::Result.new(resp.body.last)
					handle_result(r)
				rescue StandardError => e
		      Sentry.capture_exception(e)
		      handle_error([e])
		    end
			end

			# private

			# def fake_result
			# 	arr = [
			#     {
			#         "sample_no": 2500021,
			#         "lab_arrival": nil,
			#         "distribution_center_arrival": "2025-01-24",
			#         "sample_quality": 0,
			#         "rejection_reason": nil,
			#         "test_id": "c+dao-dbs",
			#         "qr_code": "N4GZ3",
			#         "item_code": "diaminooxidase",
			#         "item_value0": 6.91,
			#         "item_value1": nil
			#     }
			# 	]
			# 	Cerascreen::Labordatenbank::Result.new(arr.last)
			# end
		
		end
	end
end