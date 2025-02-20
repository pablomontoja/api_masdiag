class SendAcceptanceNotificationMailerPreview < ActionMailer::Preview
	
	def send_mail_to_patient
		sample_id = Sample.where.not(AcceptanceDate: nil).order(Id: :desc).limit(100).pluck(:Id).sample    
    MasdiagMailer::SendAcceptanceNotificationsMailer.send_mail_to_patient(sample_id)
	end
	
end