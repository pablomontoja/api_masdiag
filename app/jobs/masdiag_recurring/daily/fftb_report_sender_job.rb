module MasdiagRecurring
  module Daily

		class FftbReportSenderJob < ApplicationJob
			retry_on StandardError, wait: :polynomially_longer, attempts: 5

			def perform
				MasdiagRecurring::DailyFftbReportMailer.send_mail.deliver_later
			end

		end

	end
end
