module MasdiagRecurring
  module Monthly

    class ForeignSamplesReportJob < ApplicationJob

      def perform  
        MasdiagRecurring::MonthlyForeignSamplesReportMailer.monthly_mail.deliver_later
      end
    	
    end

  end
end