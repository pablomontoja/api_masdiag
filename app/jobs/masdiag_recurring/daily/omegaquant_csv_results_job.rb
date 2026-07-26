module MasdiagRecurring
  module Daily
    class OmegaquantCsvResultsJob < ApplicationJob
      retry_on StandardError, wait: :exponentially_longer, attempts: 5

      def perform
        institution = Institution.find_by!(name: "OmegaQuant Analytics")
        settled_before = Note.where(key: "omegaquant-result-exit-in-csv", subject_type: "Measurement").pluck(:subject_id)

        meas_ids = Measurement.includes(sample: { patient: :contractor })
                               .where.not(Id: settled_before)
                               .where.not(sample: { AcceptanceDate: nil })
                               .where(sample: { patient: { Contractors: { institution_id: institution.id } } })
                               .where(Status: 5)
                               .limit(1000)
                               .pluck(:Id)

        return if meas_ids.blank?

        MasdiagRecurring::DailyOmegaquantCsvResultsMailer.daily_mail(meas_ids).deliver_later
      end
    end
  end
end
