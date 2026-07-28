module MasdiagRecurring
  module Daily

		class LocalContractorsYearRaportJob < ApplicationJob			
			def perform				
				MasdiagRecurring::DailyLocalContractorsYearRaportMailer.send_mail.deliver_later
			end			
		end

	end
end