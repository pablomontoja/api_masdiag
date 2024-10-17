module MasdiagEvent
  class SendNotificationAfterDelayedRegMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail(email, measurements_arr)
      return if email.blank?
      @meases = Measurement.joins(:sample, :project).where(Id: measurements_arr).all
      mail(to: [email, "powiadomienia@masdiag.pl"], subject: 'Laboratorium Masdiag - powiadomienie o spóźnionym zarejestrowaniu próbki')
    end

  end
end