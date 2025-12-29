module MasdiagMailer
  class ResultNotificationMailerPreview < ActionMailer::Preview

    def contractor_result_notification_mailer
      online_file = OnlineFile.includes(measurement: { sample: { patient: :contractor } })
                              .find_by(measurement: { sample: { patient: { Contractors: { are_notifications_enabled: true } } } })
      MasdiagMailer::ContractorResultNotificationMailer.send_mail(online_file.measurement.sample.patient.ContractorId, [online_file.measurement_id])
    end

    def contractor_result_notification_lekam
      meas_id = Measurement.includes(sample: { patient: :contractor }).where(Status: 5).where(sample: { patient: { Contractors: { institution_id:  32, are_notifications_enabled: true } } }).order(Id: :desc).limit(100).pluck(:Id).sample
      online_file = OnlineFile.includes(measurement: { sample: { patient: :contractor } }).find_by(measurement_id: meas_id)
      MasdiagMailer::ContractorResultNotificationMailer.send_mail(online_file.measurement.sample.patient.ContractorId, [online_file.measurement_id])
    end

    def patient_result_notification_mailer_dp
      meas_id = Measurement.includes(sample: { patient: { contractor: :institution } })
                              .where.not(sample: { Patients: { email: nil } })
                              .where.not(sample: { Patients: { email: "" } })
                              .where.not(sample: { patient: { contractor: { institutions: { kind: "Hospital" } } } })
                              .where(Status: 5)
                              .where(sample: { patient: { Contractors: { institution_id:  33 } } })
                              .where(sample: { Patients: { send_results_on_mail: true } })
                              .order(Id: :desc).limit(100).pluck(:Id).sample
      online_file = OnlineFile.includes(measurement: { sample: { patient: { contractor: :institution } } }).find_by(measurement_id: meas_id)
      MasdiagMailer::PatientResultNotificationMailer.send_mail(online_file.measurement.sample.PatientId, [online_file.measurement_id])
    end

    def patient_result_notification_mailer_ogen
      online_file = OnlineFile.includes(measurement: { sample: { patient: { contractor: :institution } } })
                              .where(measurement: { sample: { patient: { Contractors: { institution_id:  31 } } } })
                              .where.not(measurement: { sample: { patient: { contractor: { institutions: { kind: "Hospital" } } } } })
                              .where.not(measurement: { sample: { Patients: { email: nil } } })
                              .where.not(measurement: { sample: { Patients: { email: "" } } })
                              .order(measurement_id: :desc)
                              .find_by(measurement: { sample: { Patients: { send_results_on_mail: true } } })
      MasdiagMailer::PatientResultNotificationMailer.send_mail(online_file.measurement.sample.PatientId, [online_file.measurement_id])
    end

    def patient_result_notification_mailer_lekam
      meas_id = Measurement.includes(sample: { patient: { contractor: :institution } })
                              .where.not(sample: { Patients: { email: nil } })
                              .where.not(sample: { Patients: { email: "" } })
                              .where.not(sample: { patient: { contractor: { institutions: { kind: "Hospital" } } } })
                              .where(Status: 5)
                              .where(sample: { patient: { Contractors: { institution_id:  32, are_notifications_enabled: true } } })
                              .where(sample: { Patients: { send_results_on_mail: true } })
                              .order(Id: :desc).limit(100).pluck(:Id).sample
      online_file = OnlineFile.includes(measurement: { sample: { patient: { contractor: :institution } } }).find_by(measurement_id: meas_id)
      MasdiagMailer::PatientResultNotificationMailer.send_mail(online_file.measurement.sample.PatientId, [online_file.measurement_id])
    end


  end
end