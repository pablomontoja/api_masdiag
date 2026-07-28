class DiagnostykaPrecyzyjna::ShopOrdersController < ActionController::API
  # include ActionController::HttpAuthentication::Basic::ControllerMethods
  # http_basic_authenticate_with name: "masdiag", password: "asdfghjklzxcvbnm"

  # /diagnostyka_precyzyjna/shop_orders
  def import
    @errors = []
    @shop_order = nil 

    begin
      params["_json"].each do |order|
        rso = DiagnostykaPrecyzyjna::RegShopOrder.call(order)

        if rso.success? == false
          @errors << rso.error unless rso.error.blank?
          next
        else
          @shop_order = rso.payload

          if @shop_order.save!
            if !@shop_order.package_ids.blank?
              MasdiagMailer::IndMailer.after_new_order_save(@shop_order.id).deliver_later
              MasdiagMailer::IndMailer.shipping_after_new_order(@shop_order.id).deliver_later
            end

            @shop_order.kits.select{|k| k.project_ids == [0]}.each do |kit|
              kit.products.each do |product|
                # TODO AppointmentCreationJob is working but patient_portal has error during proceeding request 
                appoint = DiagnostykaPrecyzyjna::AppointmentBuilderService.call(@shop_order, product)
                DiagnostykaPrecyzyjna::AppointmentCreationJob.perform_later(appoint)               
              end              
            end                
          end
  
        end
      end

      if @errors.count > 0
        Sentry.capture_message("DiagnostykaPrecyzyjna::ShopOrdersController - #{@errors.flatten}")
        # IndMailer.after_error(@errors.flatten).deliver_later
      end

      render plain: "OK", status: 200
    rescue StandardError => ex
      Sentry.capture_exception(ex)
      @errors << [Time.current.to_s, "Exception - #{ex}", "@shop_order - #{@shop_order.to_json}", caller_locations.join("<br>")]
      render json: { "error": ex.message }, status: 500
    end

  end

end
