module MasdiagMailer

  # Jeśli próbka została przyjęta w labie to powinna mieć przypisane badania.
  # Jeśli nie to należy wysłać alert.
  class CheckRscAssignementJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
      Sentry.capture_exception(error)
    end

    def perform(sample_id)
      return if sample_id.nil?
      sample = Sample.find(sample_id)
      return if sample.nil?
      return if sample.rsc.nil?

      if sample.rsc.reserved_tests.size.zero? && sample.measurements.size.zero? && sample.SampleStatus != 4
        MasdiagMailer::RscNotAssignedMailer.send_mail(sample.rsc).deliver_later
      end
    end

  end
end