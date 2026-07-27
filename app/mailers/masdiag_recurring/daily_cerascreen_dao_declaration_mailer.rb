module MasdiagRecurring
  class DailyCerascreenDaoDeclarationMailer < ApplicationMailer
    require 'csv'
    default :template_path => "mailers/#{self.name.underscore}"
    after_action :add_notes

    def daily_mail(rsc_ids) # rsc_ids should be an Array of sample ids
      @rscs = ReservedSampleCode.where(Id: rsc_ids).all

      csv_file_path = "tmp/#{SecureRandom.uuid}.csv"

      CSV.open(csv_file_path, "w", col_sep: ";") do |csv|     
        csv << ["qr_code", "test_id", "order_id", "sample_status"]

        @rscs.each do |rsc|
          csv << ["#{rsc.Code}", "m+dao", "A2400001", 7]
        end
      end    

      @email = 'Laborteam@cerascreen.de'    
      attachments["new-masdiag-qr-codes-#{Date.today.to_s(:db)}.csv"] = File.read(csv_file_path)

      mail(to: @email, bcc: 'pawel.swider@masdiag.pl', reply_to: "pawel.swider@masdiag.pl", subject: 'Masdiag QR Codes declaration')
    end

  private

    def add_notes()
      @rscs.each do |rsc|
        Note.create(key: "cerascreen-dao-declaration-email", subject: rsc, description: "Kod #{rsc.Code} wysłano do Cerascreen w zgłoszoniu kodów QR w ramach pliku CSV załaczonego do wiadomości email na adres #{@email} (sygnatura czasowa: #{Time.now})")
      end
    end

  end
end