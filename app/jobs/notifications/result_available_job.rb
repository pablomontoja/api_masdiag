module Notifications
  class ResultAvailableJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    # Data progu — tylko Measurement autoryzowane od tego dnia (włącznie) mogą
    # wyzwolić powiadomienie. Chroni przed masową wysyłką zaległych powiadomień
    # Toxo po naprawie mechanizmu wyzwalającego (patrz spec.md FR-001).
    CUTOFF_DATE = Date.new(2026, 9, 24).freeze

    def perform(sample_id)
      sample = Sample.find_by(Id: sample_id)
      return if sample.nil?
      return unless eligible?(sample)

      Notifications::EventDispatcher.call(event: :result_available, sample: sample)
    end

    private

    def eligible?(sample)
      sample.measurements.where("AuthorizedAt >= ?", CUTOFF_DATE).exists?
    end
  end
end
