class NotificationAfterDelayedRegMailerPreview < ActionMailer::Preview
	
	def send_mail
		sample_id = Measurement.includes(:sample).where.not(Samples: { AcceptanceDate: nil }).order(Id: :desc).limit(1000).pluck(:SampleId).sample
		meases = Measurement.joins(:sample, :project).where(SampleId: sample_id)
  	grouped_by_email = meases.group_by{ |m| m.project.responsible_person_email }
  	key = grouped_by_email.keys.first
  	values = grouped_by_email.values.first
    
    MasdiagEvent::SendNotificationAfterDelayedRegMailer.send_mail(key, values.map{|m| m.Id})
	end
	
	
end