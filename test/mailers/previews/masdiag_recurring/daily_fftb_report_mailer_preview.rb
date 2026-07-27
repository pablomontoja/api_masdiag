class DailyFftbReportMailerPreview < ActionMailer::Preview

  def send_mail
    MasdiagRecurring::DailyFftbReportMailer.send_mail
  end

end
