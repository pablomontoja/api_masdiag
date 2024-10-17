class ResultNotificationMailerPreview < ActionMailer::Preview

  def contractor_result_notification_mailer
    online_file = OnlineFile.includes(measurement: { sample: { patient: :contractor } })
                            .find_by(measurement: { sample: { patient: { Contractors: { are_notifications_enabled: true } } } })
    MasdiagMailer::ContractorResultNotificationMailer.send_mail(online_file.measurement.sample.patient.ContractorId, [online_file.measurement_id])
  end

  def contractor_result_notification_lekam
    online_file = OnlineFile.includes(measurement: { sample: { patient: :contractor } })
                            .where(measurement: { sample: { patient: { Contractors: { institution_id:  32 } } } })
                            .find_by(measurement: { sample: { patient: { Contractors: { are_notifications_enabled: true } } } })
    MasdiagMailer::ContractorResultNotificationMailer.send_mail(online_file.measurement.sample.patient.ContractorId, [online_file.measurement_id])
  end

  def patient_result_notification_mailer_dp
    online_file = OnlineFile.includes(measurement: { sample: { patient: { contractor: :institution } } })
                            .where(measurement: { sample: { patient: { Contractors: { institution_id:  33 } } } })
                            .where.not(measurement: { sample: { patient: { contractor: { institutions: { kind: "Hospital" } } } } })
                            .where.not(measurement: { sample: { Patients: { email: nil } } })
                            .where.not(measurement: { sample: { Patients: { email: "" } } })
                            .order(measurement_id: :desc)
                            .find_by(measurement: { sample: { Patients: { send_results_on_mail: true } } })
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
    online_file = OnlineFile.includes(measurement: { sample: { patient: { contractor: :institution } } })
                            .where(measurement: { sample: { patient: { Contractors: { institution_id:  32 } } } })
                            .where.not(measurement: { sample: { patient: { contractor: { institutions: { kind: "Hospital" } } } } })
                            .where.not(measurement: { sample: { Patients: { email: nil } } })
                            .where.not(measurement: { sample: { Patients: { email: "" } } })
                            .order(measurement_id: :asc)
                            .find_by(measurement: { sample: { Patients: { send_results_on_mail: true } } })
    MasdiagMailer::PatientResultNotificationMailer.send_mail(online_file.measurement.sample.PatientId, [online_file.measurement_id])
  end


end
