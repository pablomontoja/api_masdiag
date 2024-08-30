module MasdiagMailer
  class ResultNotificationMailer < ApplicationMailer
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::UrlHelper
    include ActionController::UrlFor
    include Rails.application.routes.url_helpers

    default :template_path => "mailers/#{self.name.underscore}"
    after_action :set_sendmail
    helper_method :b2b_online_file_url

    def send_mail(contractor_id, file_ids)
      byebug
      @contractor = Contractor.find(contractor_id)
      return nil if @contractor.are_notifications_enabled == false
      return nil if @contractor&.api_account

      @files = OnlineFile.where(measurement_id: file_ids)    
      attachments["pdf.jpg"] = File.read(Rails.root.join("app/assets/images/pdf.jpg"))

      attachments['ulotka.pdf'] = @contractor.institution.email_attachment_pdf if @contractor.institution.email_attachment_pdf != nil
      # byebug
      if @contractor.institution.contractor_email_template_body.blank?
        @mail = mail(to: @contractor.email, subject: 'Laboratorium Masdiag - powiadomienie')
      else
        template = ERB.new(@contractor.institution.contractor_email_template_body)
        body = template.result(binding)
        @mail = mail(to: @contractor.email, subject: 'Laboratorium Masdiag - powiadomienie') do |format|
          format.html { render html: body.html_safe }
        end      
      end
    end


  private

  	def set_sendmail		
      return nil if @files == nil
      
  		@files.each do |file|    
  			f = Fileable.new
        event = f.build_result_sending_event

        event.measurement = file.measurement
        event.sample = file.measurement.sample
        event.sent_date = Time.current
        event.sent_through = 1   # EmailNotification
        event.recipient = "Klient/Lekarz"
        event.address = @contractor.email

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

        file.update_attribute(:is_notification_send, true)
        file.update_attribute(:when_notification_send, Time.current)    
  		end
  	end

  end
end

  # ############## LIQUID #####################
  #   LIQUID_METHODS = %i{order_signature order_institution_name order_orderer_signature}

  #   def order_signature
  #     order.signature
  #   end

  #   def order_institution_name
  #     order.institution.name
  #   end

  #   def order_orderer_signature
  #     order.orderer_signature
  #   end
  # ###########################################

    
  # to było potrzebne do generowania pdf z contentu html
  # def prepare_content
  #   t = Template.find_by(owner_class: self.class.to_s)&.content
  #   return if t.nil?
  #   template = Liquid::Template.parse(t)
  #   self.content = template.render('return_doc' => self.as_json(methods: LIQUID_METHODS))
  #   self.save
  # end