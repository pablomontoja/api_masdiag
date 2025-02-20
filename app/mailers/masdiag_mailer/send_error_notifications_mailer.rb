module MasdiagMailer
  class SendErrorNotificationsMailer < ApplicationMailer
  	include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::UrlHelper
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail(params)    
      @params = params

      @mail = mail(to: "webadmin@masdiag.pl", subject: 'ERROR - powiadomienie o błędzie')
    end

  end
end