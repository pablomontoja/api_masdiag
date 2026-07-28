module MasdiagMailer
  class SendAcceptanceNotificationsMailer < ApplicationMailer
  	include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::UrlHelper
    # include EmailHelper
    # add_template_helper(EmailHelper)
    after_action :set_sendmail 
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail_to_patient(sample_id)
    	@sample = Sample.find(sample_id)
      @info = "Do pacjenta wysłano informację o przyjęciu próbki."
      @recipient = "Pacjent"
      @email_address = @sample.patient.email

      @mail = mail(to: @email_address, subject: 'Laboratorium Masdiag - powiadomienie o przyjęciu próbki do laboratorium')
    end

  private

  	def set_sendmail
      return nil if @sample.nil?
      return nil if @email_address.blank?

        f = Fileable.new
        event = f.build_result_sending_event

        event.measurement = nil
        event.sample = @sample
        event.sent_date = Time.current
        event.sent_through = 1   # EmailNotification
        event.recipient = @recipient
        event.result_text_representation = @info
        event.address = @email_address

        tmpfile = Tempfile.new([SecureRandom.uuid,'.html'], Rails.root.join('tmp') )
        tmpfile.binmode
        tmpfile.write(@mail.html_part.body.decoded)
        tmpfile.rewind

        dbfile = f.db_files.build
        # dbfile.file_content = @mail.body.encoded
        dbfile.file_content = tmpfile.read
        dbfile.file_type = "text/html"
        dbfile.file_length = dbfile.file_content.size

        f.save
        tmpfile.close
  	end

  end
end