module MasdiagMailer
  class IndMailer < ApplicationMailer
    include Rails.application.routes.url_helpers
    # self.delivery_job = SendMailNotificationDeliveryJob
  	default :template_path => "mailers/#{self.name.underscore}"

  	def after_new_order_save(shop_order_id)
      @shop_order = ShopOrder.find(shop_order_id)
  		token = Base64.urlsafe_encode64("#{@shop_order.email}/#{@shop_order.number}/#{@shop_order.time_signature}")
  		@link = root_address + "rejestracja/#{token}"
      return if @shop_order.email.blank?
  		mail(to: @shop_order.email, subject: "Diagnostyka Precyzyjna - Rejestracja Testów")
  	end

    def shipping_after_new_order(shop_order_id)
      @shop_order = ShopOrder.find(shop_order_id)
      return if @shop_order.nil?
      subject = "[Diagnostyka Precyzyjna]: Nowe zamówienie #{@shop_order.number} - ZESTAWY"
      mail(to: "logistyka@masdiag.pl", subject: subject)
    end

    def after_sample_registration(sample_id)
    	@sample = Sample.find(sample_id)
      mail(to: @sample.patient.email, subject: "Rejestracja Próbki - Masdiag Sp. z o.o.")
    end

    def aqipharm_registration(sample_id)
      @sample = Sample.find(sample_id)   
      mail(to: ["pawel.swider@masdiag.pl", "anna.kolodynska@masdiag.pl"], subject: "Rejestracja Próbki z AQI PHARM")
    end

  private

    def root_address
      (Rails.env.development? || Rails.env.test?) ? "http://127.0.0.1:3001/" : "https://rejestracja.masdiag.pl/"
    end
    
  end
end