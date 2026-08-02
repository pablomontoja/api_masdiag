module MasdiagRecurring
  class DailyCerascreenPerformanceStatisticMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail
      csv_path = MasdiagRecurring::CeraStatisticCreator.call(2).payload
      attachments["cerascreen-witd-#{Date.today}.csv"] = File.read(csv_path)

      mail(to: 'renata.halak@masdiag.pl', subject: 'Cerascreen Performance')
    end

  end
end