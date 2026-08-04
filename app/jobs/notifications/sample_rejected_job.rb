module Notifications
  class SampleRejectedJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(sample_id)
      sample = Sample.find_by(Id: sample_id)
      return if sample.nil?

      Notifications::EventDispatcher.call(event: :sample_rejected, sample: sample)
    end
  end
end
