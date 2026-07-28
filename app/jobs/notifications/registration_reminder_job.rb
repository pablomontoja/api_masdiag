module Notifications
  # Zdarzenie C — przypomnienie o rejestracji. Przyjmuje identyfikator próbki
  # (Id) lub jej kod (Code), bo dostarczona, niezarejestrowana próbka może być
  # znana LabSample tylko po kodzie.
  class RegistrationReminderJob < ApplicationJob
    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(id_or_code)
      sample = find_sample(id_or_code)
      return if sample.nil?

      Notifications::EventDispatcher.call(event: :registration_reminder, sample: sample)
    end

    private

    def find_sample(id_or_code)
      Sample.find_by(Id: id_or_code) || Sample.find_by(Code: id_or_code)
    end
  end
end
