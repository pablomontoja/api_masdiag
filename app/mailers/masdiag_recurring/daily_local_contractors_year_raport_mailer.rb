class LocalContractorsYearRaportMailer < ApplicationMailer
  default :template_path => "mailers/#{self.name.underscore}"

  def send_mail(path)
  	attachments["klienci-krajowi-#{Date.today}.xlsx"] = File.read(path)

    mail(to: 'dariusz.kolodynski@masdiag.pl', subject: 'Klienci krajowy - raport z przyjęcia próbek')
  end
end