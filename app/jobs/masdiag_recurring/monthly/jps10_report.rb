module MasdiagRecurring
  module Monthly

    class Jps10Report < ApplicationJob

      def perform
        MasdiagRecurring::MonthlyJps10RaportMailer.send_mail.deliver_later
      end

    end

  end
end
