module Notifications
  # Zdarzenie D — powtórne przypomnienie o rejestracji. Uruchamiane cyklicznie
  # (config/recurring.yml). Wybiera kwalifikujące się próbki i wysyła powiadomienie;
  # idempotencję zapewnia Note (RegistrationRemindersFinder pomija już powiadomione).
  class RegistrationReminderFinalJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform
      Notifications::RegistrationRemindersFinder.call.each do |sample|
        Notifications::EventDispatcher.call(event: :registration_reminder_final, sample: sample)
      end
    end
  end
end
