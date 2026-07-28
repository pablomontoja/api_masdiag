module MasdiagMailer
	class MasdiagPlContactFormMailer < ApplicationMailer
	  include Rails.application.routes.url_helpers
		default :template_path => "mailers/#{self.name.underscore}"

		def send_mail(msg)		
			@msg = OpenStruct.new(name: msg[:name], email: msg[:email], message: msg[:message] )
	    return if @msg.email.blank?
			mail(to: "pomoc@masdiag.pl", reply_to: [@msg.email, "pomoc@masdiag.pl"], subject: "Strona www.masdiag.pl - formularz kontaktowy")
		end

	end
end