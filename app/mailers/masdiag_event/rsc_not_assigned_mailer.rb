module MasdiagEvent
  class RscNotAssignedMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail(rsc)
      @rsc = rsc
      mail(to: "pawel.swider@masdiag.pl", subject: 'ALERT - nieprzypisane badania do nośnika')
    end

  end
end