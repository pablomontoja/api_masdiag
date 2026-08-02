module Notifications
  class ResultAvailableJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(sample_id)
      sample = Sample.find_by(Id: sample_id)
      return if sample.nil?

      Notifications::EventDispatcher.call(event: :result_available, sample: sample)
    end
  end
end
