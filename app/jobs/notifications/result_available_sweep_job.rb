module Notifications
  # Bezpiecznik dla powiadomień Toxo result_available: znajduje autoryzowane
  # pomiary, dla których nie wysłano jeszcze powiadomienia (patrz
  # UnnotifiedToxoResultsFinder), i wyzwala je bezpośrednio. Uruchamiany z
  # EmailsController#send_all obok ContractorResultsNotifierJob/
  # PatientResultsNotifierJob — nie zastępuje wyzwalacza per-zdarzeniowego
  # (POST /masdiag/result_available/:measurement_id), tylko łapie pominięte
  # wywołania.
  class ResultAvailableSweepJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform
      Notifications::UnnotifiedToxoResultsFinder.call.each do |measurement|
        Notifications::EventDispatcher.call(event: :result_available, measurement: measurement)
      end
    end
  end
end
