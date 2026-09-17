module DiagnostykaPrecyzyjna
  class RegShopOrder < ApplicationService
    require 'php_serialize'
    attr_accessor :params, :shop_order, :errors

    def initialize(params)
      @params = params.to_unsafe_h
      @shop_order = ShopOrder.new
      @errors = []
    end

    def call
      begin
        prepare_shop_order()

        return handle_error() if ShopOrder.find_by(number: @shop_order.number).present?

        if @shop_order.email.blank? || @shop_order.email == "t.bialik@avatar-pr.com" || @shop_order.email == "tab76@wp.pl" || @shop_order.email == "t.bialik@arcandberg.com"
          @errors << ["Zamówienie sklepu DP - nr #{@shop_order.number}", "Nie przekazano adresu email lub jest on zablokowany!", params]
          return handle_error(@errors)
        end

        ActiveRecord::Base.transaction do
          prepare_ordered_kits()
          raise ActiveRecord::Rollback if @errors.count > 0
        end

        if @errors.count > 0
          Sentry.capture_message(@errors.flatten.join("; "))
          return handle_error(@errors.flatten)
        else
          return handle_result(@shop_order)
        end

      rescue Exception => ex
        Sentry.capture_exception(ex)
        @errors << [Time.current.to_s, "Exception - #{ex}", "shop_order - #{@shop_order.to_json}", caller_locations.join("<br>")]
        return handle_error(@errors.flatten)
      end
    end

    private

    def prepare_shop_order()
      @shop_order.number = @params["order_number"]
      @shop_order.time_signature = @params["order_date"]
      @shop_order.first_name = @params["billing_first_name"]
      @shop_order.last_name = @params["billing_last_name"]
      @shop_order.email = @params["billing_email"]
      @shop_order.phone = @params["billing_phone"]
      @shop_order.package_ids = []
    end

    def prepare_ordered_kits()
      coupons_json = @params["coupons"]
      coupons = []
      coupons_json.each do |c|
        coupons << ShopOrders::Coupon.new(c).call
      end
      @shop_order.coupons = coupons

      kits_json = @params["products"]

      kits = []
      kits_json.each do |shop_kit|
        next if shop_kit["Product Name (main)"].include?("Badanie mikroflory jelitowej")

        mixed_kits = []
        mixed_kits += ShopOrders::MixedKits.new(shop_kit, coupons).call
        kits += mixed_kits
        next if mixed_kits.size > 0

        kit = ShopOrders::Kit.new(shop_kit, coupons).call
        kits << kit
      end

      kits.each do |k|
        next if k.products.any?{|prod| prod.name.include?("Konsultacja")}
        inst_id = 33
        # inst_id = 100 if  k.products.any?{ |prod| prod.name == "Badanie Federacja Nordic Walking" }
        nordic_walking_check = (k.project_ids.to_set == [2, 12].to_set) && k.products.any?{ |prod| prod.name == "Badanie Federacja Nordic Walking" }

        k.quantity.times do
          rsc = prepare_rsc(k.project_ids, inst_id) unless nordic_walking_check
          rsc = prepare_rsc(k.project_ids, 100) if nordic_walking_check
          if rsc
            @shop_order.package_ids = @shop_order.package_ids + [rsc.package.id]
            stock_room_out(rsc)
          end
        end
      end


      @shop_order.kits = kits
      @shop_order.total_cost = kits.sum(&:cost)
      @shop_order.total_cost_with_coupons = kits.sum(&:cost_with_discount)
    end

    def prepare_rsc(project_ids, inst_id)
      rsc = Shopify::RscAllocator.call(project_ids, { inst_id: inst_id })

      if rsc.nil?
        @errors << [Time.current.to_s, "Serwer API w aplikacji INDCLIENTS2 nie jest w stanie znaleźć ani jednego dostępnego pudełka na magazynie.", "klasa: RegShopOrder, metoda: prepare_rsc", "\r\n"]
      end

      rsc
    end

    def stock_room_out(rsc)
      rsc.package.update!(comment: "Pudełko zakupione w sklepie Diagnostyka Precyzyjna (zamówienie sklepu - #{@shop_order.number}, email zamawiającego - #{@shop_order.email})")
      rsc.package.stock_room_item.update!(remaining_quantity: 0, date_out: Time.current)
    end


  end
end