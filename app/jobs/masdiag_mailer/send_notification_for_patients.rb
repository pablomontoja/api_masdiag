module MasdiagMailer
  class SendNotificationForPatients < ApplicationJob

    def perform()
    	# files = OnlineFile.includes(measurement: { sample: :patient }).where(is_patient_notification_send: false).select("measurement_id")
      four_months_ago = 4.months.ago
      patients_ids = Patient.where(send_results_on_mail: true).where.not(email: [nil, '']).where.not(ContractorId: 125).pluck(:Id)
      files = OnlineFile.includes(measurement: { sample: :patient })
                        .where(is_patient_notification_send: false)
                        .where("Measurements.AuthorizedAt > ?", four_months_ago)
                        .where(measurement: { Samples: {PatientId: patients_ids}})
                        .where(measurement: { Samples: {payment_status: [nil, 0, 1]}})
                        .pluck(:measurement_id, :"Samples.PatientId")

      
    	return nil if files.count == 0
     #  files = files.select{|x| x.measurement.sample.patient != nil}
     #  files = files.select{ |c| c.measurement.sample.patient.ContractorId != 55 }  ##################################### klienci idywidualni
     #  files = files.select{|x| [0,1].include?(x.measurement.sample.payment_status) }

      files.each do |file|
        file_id = file[0]
        patient_id = file[1]

        patient = Patient.find(patient_id)
        next if patient.email.blank? || !patient.send_results_on_mail || patient.email == "null"
        next if patient&.contractor&.api_account
        next if patient&.contractor&.institution&.kind == "Hospital" && patient&.contractor&.institution_id != 69

        PatientResultNotificationMailer.send_mail(patient_id, file_id).deliver_later
      end
    	
    	# h = Hash.new  # hash gdzie kluczami są idki z OnlineFile a wartościami są idki z Patients
     # 	files.collect{|x| h[x[0]] = x[1]} # generowanie tablicy hashy
    	# patients = h.values.uniq # kompresja patientów

    	# patients.each do |patient|
    	# 	patient_files = h.select{|x,y| y==patient}

     #    pat = Patient.find(patient)
     #    next if pat.email.blank? || !pat.send_results_on_mail
    	# 	file_ids = patient_files.keys      

    	# 	PatientResultNotificationMailer.send_mail(patient, file_ids).deliver_later
     #    # PatientResultNotificationMailer.send_special_mail(patient, file_ids).deliver_later if pat.ContractorId == 373 # targi@masdiag.pl
    	# end
      # Do something later
    end

  end
end
