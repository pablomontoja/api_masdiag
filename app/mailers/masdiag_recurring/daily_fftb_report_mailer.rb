class DailyFftbReportMailer < ApplicationMailer
  require 'csv'
  default :template_path => "mailers/#{self.name.underscore}"

  def daily_mail(file_path) # rsc_ids should be an Array of sample ids        
    attachments["masdiag-report-fftb-#{Date.today.to_s(:db)}.csv"] = File.read(file_path)

    mail(to: ["tests@foodforthebrain.org", "dariusz.kolodynski@masdiag.pl"], reply_to: "pawel.swider@masdiag.pl", subject: 'FFTB Samples Report')
  end

end
