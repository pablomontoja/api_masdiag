class ContractorResultNotificationMailerPreview < ActionMailer::Preview
  def contractor_result_notification
    online_file = OnlineFile.includes(measurement: { sample: { patient: :contractor } }).find_by(measurement: { sample: { patient: { Contractors: { are_notifications_enabled: true } } } })
    MasdiagMailer::ContractorResultNotificationMailer.send_mail(online_file.measurement.sample.patient.ContractorId, [online_file.measurement_id])
  end
end
