module Notifications
  class ResultAvailableJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    # Data progu — tylko Measurement autoryzowane od tego dnia (włącznie) mogą
    # wyzwolić powiadomienie. Chroni przed masową wysyłką zaległych powiadomień
    # Toxo po naprawie mechanizmu wyzwalającego (patrz spec.md FR-001).
    CUTOFF_DATE = Date.new(2026, 9, 29).freeze

    def perform(measurement_id)
      measurement = Measurement.find_by(Id: measurement_id)
      return if measurement.nil?
      return unless eligible?(measurement)

      Notifications::EventDispatcher.call(event: :result_available, measurement: measurement)
    end

    private

    def eligible?(measurement)
      measurement.AuthorizedAt.present? && measurement.AuthorizedAt >= CUTOFF_DATE
    end
  end
end
