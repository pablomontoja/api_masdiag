module MasdiagMailer
  class IndMailer < ApplicationMailer
    include Rails.application.routes.url_helpers
  	default :template_path => "mailers/#{self.name.underscore}"

  	def after_new_order_save(shop_order_id)
      @shop_order = ShopOrder.find(shop_order_id)
  		token = Base64.urlsafe_encode64("#{@shop_order.email}/#{@shop_order.number}/#{@shop_order.time_signature}")
  		@link = registration_root_address + "rejestracja/#{token}"
      return if @shop_order.email.blank?

      if @shop_order.source == "shopify"
        mail(to: @shop_order.email, subject: "Rare Disease Diagnostics - Test Registration",
             template_name: "after_new_order_save_shopify")
      else
        mail(to: @shop_order.email, subject: "Diagnostyka Precyzyjna - Rejestracja Testów")
      end
  	end

    def shipping_after_new_order(shop_order_id)
      @shop_order = ShopOrder.find(shop_order_id)
      return if @shop_order.nil?
      subject = "[Sklep Internetowy]: Nowe zamówienie #{@shop_order.number} (#{@shop_order.source}) - ZESTAWY"
      mail(to: "logistyka@masdiag.pl", subject: subject)
    end

    def after_sample_registration(sample_id)
    	@sample = Sample.find(sample_id)
      return if @sample.patient&.email.blank?

      mail(to: @sample.patient.email, subject: "Rejestracja Próbki - Masdiag Sp. z o.o.")
    end

  private

    def registration_root_address
      return shopify_root_address if @shop_order.source == "shopify"

      (Rails.env.development? || Rails.env.test?) ? "http://127.0.0.1:3001/" : "https://rejestracja.masdiag.pl/"
    end

    def shopify_root_address
      (Rails.env.development? || Rails.env.test?) ? "http://127.0.0.1:3001/" : "https://results.rarediagnostics.eu/"
    end
    
  end
end