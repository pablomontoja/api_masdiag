module MasdiagEvent
  class SendNotificationAfterDelayedRegJob < ApplicationJob
    require 'json'
    queue_as :default

    def perform(sample_id)
    	meases = Measurement.joins(:sample, :project).where(SampleId: sample_id)
    	grouped_by_email = meases.group_by{ |m| m.project.responsible_person_email }
      grouped_by_email.each do |k, v|
        MasdiagEvent::SendNotificationAfterDelayedRegMailer.send_mail(k, v.map{|m| m.Id}).deliver_later
      end
    end

  end
end