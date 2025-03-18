module MasdiagMailer

  # Ten job odpowiada za wyszukiwanie niewysłanych raportów z wynikami w kontekście samego pacjenta.
  # Dla znalezionych wyników job uruchamia mailer PatientResultNotificationMailer, aby wysłać powiadomienie do pacjentów.
  class PatientResultsNotifierJob < ApplicationJob
    def perform
      return unless eligible_files_exist?
      
      process_eligible_files
    end

    private

    def eligible_files_exist?
      eligible_files.any?
    end
    
    def eligible_files
      @eligible_files ||= OnlineFile
        .eager_load(measurement: { sample: :patient })        
        .where(is_patient_notification_send: false)        
        .where(
          measurement: { 
            Samples: {
              PatientId: eligible_patient_ids,
              payment_status: [nil, 0, 1]
            }
          }
        )
        .where(measurement: { AuthorizedAt: 4.months.ago..DateTime::Infinity.new })
        .pluck(:measurement_id, :"Samples.PatientId")
    end

    def eligible_patient_ids
      @eligible_patient_ids ||= Patient
        .where(send_results_on_mail: true)
        .where.not(email: [nil, ''])
        .where.not(ContractorId: 125)
        .pluck(:Id)
    end

    def process_eligible_files
      eligible_files.each do |file_id, patient_id|
        patient = Patient.find(patient_id)
        
        next unless should_send_notification?(patient)
        
        PatientResultNotificationMailer.send_mail(patient_id, file_id).deliver_later
      end
    end

    def should_send_notification?(patient)
      return false if patient.email.blank? || !patient.send_results_on_mail || patient.email == "null"
      return false if patient&.contractor&.api_account
      return false if patient&.contractor&.institution&.kind == "Hospital" && patient&.contractor&.institution_id != 69

      true
    end
  end


end




