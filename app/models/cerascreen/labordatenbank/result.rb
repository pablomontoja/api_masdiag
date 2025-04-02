module Cerascreen
	module Labordatenbank
		class Result
			include ActiveModel::Model
			include ActiveModel::Attributes
			include ActiveModel::Serializers::JSON

			attribute :sample_no, :integer
			attribute :lab_arrival, :datetime
			attribute :distribution_center_arrival, :datetime
			attribute :sample_quality, :integer
			attribute :rejection_reason, :string
			attribute :test_id, :string
			attribute :qr_code, :string
			attribute :item_code, :string
			attribute :item_value0, :decimal
			attribute :item_value1, :decimal
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