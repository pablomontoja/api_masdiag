module MasdiagMailer
	class SendErrorNotificationsMailerPreview < ActionMailer::Preview

		def send_mail
			params = { SendCancellationNotificationsJob: "ERROR: RuntimeError - example error message", SampleCode: "12345" }
			MasdiagMailer::SendErrorNotificationsMailer.send_mail(params)
		end

	end
end
