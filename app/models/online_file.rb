class OnlineFile < ApplicationRecord
	self.primary_key = "measurement_id"

	belongs_to :measurement

	def readonly?
	  Rails.env.test? ? false : true
	end
	
end
