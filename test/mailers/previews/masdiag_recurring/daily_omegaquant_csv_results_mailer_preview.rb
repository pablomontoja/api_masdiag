class DailyOmegaquantCsvResultsMailerPreview < ActionMailer::Preview

  def daily_mail
    institution = Institution.find_by(name: "OmegaQuant Analytics")
    meas_ids = Measurement.includes(sample: { patient: :contractor })
                           .where(sample: { patient: { Contractors: { institution_id: institution&.id } } })
                           .where(Status: 5)
                           .limit(1000)
                           .pluck(:Id)

    MasdiagRecurring::DailyOmegaquantCsvResultsMailer.daily_mail(meas_ids)
  end

end
