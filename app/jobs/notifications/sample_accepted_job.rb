module Notifications
  class SampleAcceptedJob < ApplicationJob
    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(sample_id)
      sample = Sample.find_by(Id: sample_id)
      return if sample.nil?

      Notifications::EventDispatcher.call(event: :sample_accepted, sample: sample)
    end
  end
end
