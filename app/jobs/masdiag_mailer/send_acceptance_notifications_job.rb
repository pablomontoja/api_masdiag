module MasdiagMailer
  class SendAcceptanceNotificationsJob < ApplicationJob
    require 'json'
    # include Sidekiq::Worker

    queue_as :default

    def perform(sample_ids)
      begin

        sample_ids.each do |sample_id|
          @sample = Sample.find(sample_id)
          next if @sample == nil
          next if @sample&.patient&.contractor&.api_account

          patient_email = @sample.patient&.email
          MasdiagMailer::SendAcceptanceNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if !patient_email.blank?
        end

      rescue StandardError => err
        MasdiagMailer::SendErrorNotificationsMailer.send_mail({SendAcceptanceNotificationsJob: "ERROR: #{err}", SampleCode: @sample.Code})
      end
    end


  end
end
