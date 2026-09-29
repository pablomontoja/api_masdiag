module Masdiag
  # Ujednolicone endpointy zdarzeń cyklu życia próbki wywoływane przez LabSample.
  # LabSample zgłasza wyłącznie zdarzenie (np. "sample_accepted") — to ta aplikacja
  # wybiera szablon (laboratoryjny vs Toxo) na podstawie instytucji próbki.
  class NotificationsController < ApplicationController
    include MasdiagCheck

    # POST /masdiag/sample_accepted
    def sample_accepted
      enqueue_by_id(Notifications::SampleAcceptedJob)
    end

    # POST /masdiag/sample_rejected
    def sample_rejected
      enqueue_by_id(Notifications::SampleRejectedJob)
    end

    # POST /masdiag/result_available/:measurement_id
    def result_available
      measurement = Measurement.find_by(Id: params[:measurement_id])
      return render_measurement_not_found if measurement.nil?

      Notifications::ResultAvailableJob.perform_later(measurement.Id)
      json_response("OK")
    end

    # POST /masdiag/registration_reminder  (accepts sample_id or code)
    def registration_reminder
      identifier = params[:sample_id].presence || params[:code].presence
      return render_sample_not_found if identifier.blank?
      return render_sample_not_found unless sample_exists_for?(identifier)

      Notifications::RegistrationReminderJob.perform_later(identifier)
      json_response("OK")
    end

    private

    def enqueue_by_id(job_class)
      sample = Sample.find_by(Id: params[:sample_id])
      return render_sample_not_found if sample.nil?

      job_class.perform_later(sample.Id)
      json_response("OK")
    end

    def sample_exists_for?(identifier)
      Sample.exists?(Id: identifier) || Sample.exists?(Code: identifier)
    end

    def render_sample_not_found
      json_response({ error: "sample not found" }, :unprocessable_content)
    end

    def render_measurement_not_found
      json_response({ error: "measurement not found" }, :unprocessable_content)
    end
  end
end
