module MasdiagRecurring
  module Daily

		class FftbReportSenderJob < ApplicationJob

			def perform				
				MasdiagRecurring::DailyFftbReportMailer.send_mail.deliver_later
			end

		end

	end
end
