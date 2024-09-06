module MasdiagMailer

  # Ten job odpowiada za wyszukiwanie niewysłanych raportów z wynikami w kontekście samego pacjenta.
  # Dla znalezionych wyników job uruchamia mailer PatientResultNotificationMailer, aby wysłać powiadomienie do pacjentów.
  class PatientResultsNotifierJob < ApplicationJob

    def perform()
      four_months_ago = 4.months.ago
      patients_ids = Patient.where(send_results_on_mail: true).where.not(email: [nil, '']).where.not(ContractorId: 125).pluck(:Id)
      files = OnlineFile.includes(measurement: { sample: :patient })
                        .where(is_patient_notification_send: false)
                        .where("Measurements.AuthorizedAt > ?", four_months_ago)
                        .where(measurement: { Samples: {PatientId: patients_ids}})
                        .where(measurement: { Samples: {payment_status: [nil, 0, 1]}})
                        .pluck(:measurement_id, :"Samples.PatientId")
      
    	return nil if files.count == 0

      files.each do |file|
        file_id = file[0]
        patient_id = file[1]

        patient = Patient.find(patient_id)
        next if patient.email.blank? || !patient.send_results_on_mail || patient.email == "null"
        next if patient&.contractor&.api_account
        next if patient&.contractor&.institution&.kind == "Hospital" && patient&.contractor&.institution_id != 69

        PatientResultNotificationMailer.send_mail(patient_id, file_id).deliver_later
      end
    end

  end
end
