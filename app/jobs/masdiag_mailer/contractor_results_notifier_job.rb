module MasdiagMailer

  # Ten job odpowiada za wyszukiwanie raportów PDF w tabeli OnlineFile, które nie zostały do tej pory wysłane.
  # Następnie job uruchamia mailer ContractorResultNotificationMailer, aby wysłać powiadomienie do Contractorów.
  # metoda #perform - nie wymaga żadnych parametrów, opiera swoje działanie na danych znalezionych w bazie danych.
  class ContractorResultsNotifierJob < ApplicationJob
    def perform
      # Find contractors with enabled notifications
      contractor_ids = Contractor.where(are_notifications_enabled: true).pluck(:Id)
      
      # Find unnotified files for these contractors with their respective contractor IDs
      files = OnlineFile.includes(measurement: { sample: { patient: :contractor }})
                        .where(measurement: { sample: { Patients: { ContractorId: contractor_ids } } })
                        .where(is_notification_send: false)
                        .pluck(:measurement_id, :"Patients.ContractorId")
      
      # Return early if no files found
      return if files.empty?
      
      # Group files by contractor ID
      files_by_contractor = files.each_with_object({}) do |(measurement_id, contractor_id), hash|
        hash[contractor_id] ||= []
        hash[contractor_id] << measurement_id
      end
      
      # Send notification email to each contractor
      files_by_contractor.each do |contractor_id, file_ids|
        mail = MasdiagMailer::ContractorResultNotificationMailer.send_mail(contractor_id, file_ids)
        mail&.deliver_later
      end
    end
    
  end
end
