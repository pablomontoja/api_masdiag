module MasdiagRecurring
  class MonthlyDecretionReportMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def monthly_mail(message)
      @message = message.join("\n")

      mail(to: ['webadmin@masdiag.pl', 'anna.kolodynska@masdiag.pl', 'anna.grabowska@masdiag.pl'], subject: 'Realizacja dużych zamówień krajowych')
    end

  end
end