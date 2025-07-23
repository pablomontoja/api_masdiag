module MasdiagRecurring
  module Daily
    class CerascreenPerformanceStatisticJob < ApplicationJob

      def perform      	
        MasdiagRecurring::DailyCerascreenPerformanceStatisticMailer.send_mail.deliver_later
      end
    	
    end
  end
end
