module MasdiagMailer
	class MasdiagPlContactFormMailerPreview < ActionMailer::Preview
		
		def send_mail
			msg = { name: "Jan Kowalski", email: "jan@kowalski.pl", message: "Jestem Jan Kowalski i mam problem." }
	    MasdiagMailer::MasdiagPlContactFormMailer.send_mail(msg)
		end
		
	end
end