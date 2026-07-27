module MasdiagRecurring
  class DailyFftbReportMailer < ApplicationMailer
    default template_path: "mailers/#{self.name.underscore}"

    def send_mail
      result = MasdiagRecurring::FftbReportGenerator.call

      attachments["masdiag-report-fftb-#{Date.today}.csv"] = result.payload

      mail(to: ["tests@foodforthebrain.org", "logistyka@masdiag.pl"], reply_to: "pawel.swider@masdiag.pl", subject: 'FFTB Samples Report')
    end
  end
end