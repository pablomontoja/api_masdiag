module MasdiagRecurring
  module Hourly

    class DelayedJobsMonitoringJob < ApplicationJob

      def perform
        puts "---------------------------------------------------------"
        puts "MasdiagRecurring::Hourly::DelayedJobsMonitoringJob"
        puts "---------------------------------------------------------"
        
        Delayed::Backend::ActiveRecord::Job.table_name = "delayed_jobs"
        jobs = Delayed::Job.where("attempts > 3")

        if jobs.count > 0
          result_hash = {"HourlyMonitoringJob": "#{DateTime.now.to_s(:db)} - wykryto błędy dla zadań DELAYED_JOB w aplikacji rejestracja"}
          jobs.each do |job|
            result_hash["#{job.id}"] = "ERROR FOR: #{job.handler}, ERROR: #{job.last_error}"
          end
          MasdiagMailer::SendErrorNotificationsMailer.send_mail(result_hash).deliver_later
        else
          puts "no error found for rejestracja"
        end


        Delayed::Backend::ActiveRecord::Job.table_name = "rejestracja2_delayed_jobs"
        jobs_rej2 = Delayed::Job.where("attempts > 3")
        Delayed::Backend::ActiveRecord::Job.table_name = "delayed_jobs"

        if jobs_rej2.count > 0
          result_hash = {"HourlyMonitoringJob": "#{DateTime.now.to_s(:db)} - wykryto błędy dla zadań DELAYED_JOB w aplikacji rejestracja2"}
          jobs_rej2.each do |job|
            result_hash["#{job.id}"] = "ERROR FOR: #{job.handler}, ERROR: #{job.last_error}"
          end
          MasdiagMailer::SendErrorNotificationsMailer.send_mail(result_hash).deliver_later
        else
          puts "no error found for rejestracja2"
        end


        Delayed::Backend::ActiveRecord::Job.table_name = "order_panel_delayed_jobs"
        jobs_order_panel = Delayed::Job.where("attempts > 3")
        Delayed::Backend::ActiveRecord::Job.table_name = "delayed_jobs"

        if jobs_order_panel.count > 0
          result_hash = {"HourlyMonitoringJob": "#{DateTime.now.to_s(:db)} - wykryto błędy dla zadań DELAYED_JOB w aplikacji order_panel"}
          jobs_order_panel.each do |job|
            result_hash["#{job.id}"] = "ERROR FOR: #{job.handler}, ERROR: #{job.last_error}"
          end
          MasdiagMailer::SendErrorNotificationsMailer.send_mail(result_hash).deliver_later
        else
          puts "no error found for order_panel"
        end


        Delayed::Backend::ActiveRecord::Job.table_name = "storage_delayed_jobs"
        jobs_storage = Delayed::Job.where("attempts > 3")
        Delayed::Backend::ActiveRecord::Job.table_name = "delayed_jobs"

        if jobs_storage.count > 0
          result_hash = {"HourlyMonitoringJob": "#{DateTime.now.to_s(:db)} - wykryto błędy dla zadań DELAYED_JOB w aplikacji storage"}
          jobs_storage.each do |job|
            result_hash["#{job.id}"] = "ERROR FOR: #{job.handler}, ERROR: #{job.last_error}"
          end
          MasdiagMailer::SendErrorNotificationsMailer.send_mail(result_hash).deliver_later
        else
          puts "no error found for storage"
        end
   
        puts "---------------------------------------------------------"
      end
    end
  
  end
end
