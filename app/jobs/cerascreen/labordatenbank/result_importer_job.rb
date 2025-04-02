module Cerascreen
	module Labordatenbank
		class ResultImporterJob < ApplicationJob
			retry_on StandardError, wait: :exponentially_longer, attempts: 5 do |job, error|
		    Sentry.capture_exception(error)
		  end

		  # result must be a Cerascreen::Labordatenbank::Result type
			def perform(sample_code)
				resp = Cerascreen::Labordatenbank::GetResultSvc.call(sample_code)
				meas = Measurement.includes(:sample).where(Status: [1, 2], ProjectId: 24).find_by(sample: { Code: sample_code })
				cresult = resp.payload

				return nil if cresult.nil?

				if meas&.Status == 1
					Sentry.capture_message("Próbka DAO, kod #{sample_code} nie została wycięta na płytkę!!!", level: :fatal)
					return nil
				end

				user = User.find(24) # Renata Halak

				success = false

				ActiveRecord::Base.transaction do
					analyte = Analyte.find(323)
					db_result = ::Result.create!(MeasurementId: meas.Id, ImportDate: Time.now, IsValid: true, ImportUserId: user.Id, PlateCode: meas.plate_measurement.plate.Code)
					db_result.analyte_results.create!(AnalyteId: analyte.Id, Value: cresult.item_value0, Unit: analyte.Unit, MeasuredValue: cresult.item_value0)
					meas.update!(Status: 4, MeasureDate: Time.now, InstrumentId: 11)
					meas.plate_measurement.plate.update!(ResultWasAdded: true, ResultWasAddedDate: Time.now) if meas.plate_measurement.plate.ResultWasAdded == false
					success = true
				end
				
				Sentry.capture_message("Próbka DAO, kod #{sample_code} wymaga autoryzacji!!!", level: :warning) if success
			end
		end
	end
end


# [
# 	{
# 		"sample_no"=>2507002,                           
# 	  "lab_arrival"=>"2025-03-26",                    
# 	  "distribution_center_arrival"=>"2025-03-26",    
# 	  "sample_quality"=>0,                            
# 	  "rejection_reason"=>nil,                        
# 	  "test_id"=>"m+DAO MasDiag",                     
# 	  "qr_code"=>"ABC821",                            
# 	  "item_code"=>"diaminooxidase",                  
# 	  "item_value0"=>25.3,                            
# 	  "item_value1"=>nil
#   }
# ] 
# N4GZ3