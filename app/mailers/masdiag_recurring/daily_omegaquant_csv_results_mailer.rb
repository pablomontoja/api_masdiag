module MasdiagRecurring
  class DailyOmegaquantCsvResultsMailer < ApplicationMailer
    default template_path: "mailers/#{self.name.underscore}"
    after_action :add_notes

    def daily_mail(meas_ids)
      result = MasdiagRecurring::OmegaquantCsvResultsGenerator.call(meas_ids)
      @measurement_ids = result.payload[:measurement_ids]

      attachments["results-#{Date.today.strftime('%Y-%m-%d')}.csv"] = result.payload[:csv]

      mail(to: 'jason@omegaquant.com', cc: 'james@omegaquant.com', bcc: 'pawel.swider@masdiag.pl', subject: 'CSV Results')
    end

    private

    def add_notes
      Measurement.where(Id: @measurement_ids).each do |meas|
        Note.create!(key: "omegaquant-result-exit-in-csv", subject: meas, description: "Result sent in CSV to jason@omegaquant.com at #{Time.now.strftime('%F')}")
      end
    end
  end
end
