module MasdiagEvent

  # Jeśli próbka rejestrowana jest przez pacjenta już po dotarciu próbki do laboratorium, konieczne jest poinformowanie 
  # osób, które odpowiadają za wykonanie zleconych pomiarów. Jeśli wynik pomiaru jest już gotowy to konieczne jest przeliczenie wyniku 
  # i autoryzacja używając LabSample.  
  class SendNotificationAfterDelayedRegJob < ApplicationJob
    require 'json'

    def perform(sample_id)
    	meases = Measurement.where.not(Status: 5).joins(:sample, :project).where(SampleId: sample_id)
    	grouped_by_email = meases.group_by{ |m| m.project.responsible_person_email }
      grouped_by_email.each do |k, v|
        MasdiagEvent::SendNotificationAfterDelayedRegMailer.send_mail(k, v.map{|m| m.Id}).deliver_later
      end
    end

  end
end