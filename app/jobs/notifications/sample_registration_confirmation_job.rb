module Notifications
  # Zdarzenie A — potwierdzenie zlecenia (+ PDF). Wyzwalane po udanej rejestracji
  # próbki w portalu Toxo. Błąd generowania PDF jest przechwytywany i raportowany
  # (Sentry w produkcji), aby nie wpłynąć na zakończoną już rejestrację.
  class SampleRegistrationConfirmationJob < ApplicationJob
    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(sample_id)
      sample = Sample.find_by(Id: sample_id)
      return if sample.nil?

      Notifications::EventDispatcher.call(event: :sample_registration_confirmation, sample: sample)
    rescue Prawn::Errors::PrawnError, IOError => e
      Sentry.capture_exception(e) if defined?(Sentry) && Rails.env.production?
      nil
    end
  end
end
