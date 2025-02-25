module MasdiagRecurring
  module Hourly

    class FailedExecutionMonitoringJob < ApplicationJob
      def perform
        failed_executions = SolidQueue::FailedExecution.all
        return nil if failed_executions.size.zero?

        result_hash = {}
        result_hash["FailedExecutionMonitoringJob"] = "SolidQueue::FailedExecution are present in database."
        
        SolidQueue::FailedExecution.all.each do |fe|
          result_hash["#{fe.job.active_job_id}"] = "ERROR FOR: #{fe.job.class_name}, JOB ARGUMENTS: #{fe.job.arguments}, ERROR: #{fe.error}"
        end

        MasdiagMailer::SendErrorNotificationsMailer.send_mail(result_hash).deliver_later
      end
    end

  end
end