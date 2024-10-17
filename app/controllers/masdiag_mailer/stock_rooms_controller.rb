module MasdiagMailer
	class StockRoomsController < ApplicationController
		include MasdiagCheck

		# protect_from_forgery except: [:stock_out_by_packages, :stock_out_by_shipment, :back_to_stock_by_shipment]

		# The endpoint used by order_panel
		# GET /api/stock_room/is_package_in_stock/:package_id
		def is_package_in_stock
			begin
				pack = Package.find(params[:id])

				if pack.stock_room_item.date_out.nil? && pack.stock_room_item.remaining_quantity > 0
		      render json: { "package_in_stock": true, "stock_room_name": "#{pack.stock_room_item.stock_room.name}" }, status: 200
		    else
		    	render json: { "package_in_stock": false }, status: 200
					return
				end

	    rescue Exception => e
	      render json: { "error": e }, status: 500
	    end
		end

	  # It is likely that this endpoint is not used by anyone.
		# package_ids: [], institution_id: nil, comment: nil
		# {
		#    "package_ids": [
		#        14039,
		#        14040
		#    ],
		#    "institution_id": 2,
		#    "comment": "testowy komentarz"
		# }
		# POST 
		def stock_out_by_packages		
			res = StockOutByPackagesService.call(by_packages_allowed_params)
	    if res.success?
	      render json: { "notice": "Opakowania zostały prawidłowo przypisane do Instytucji oraz zdjęte z magazynu." }, status: 200
	    else
	      @errors = res.error
	      render json: { "errors": @errors }, status: 500
	    end
		end

	  # The endpoint used by order_panel
		# {
		#    "shipment_id": 1,
		#    "institution_id": 2,
		#    "comment": "testowy komentarz"
		# }
		# POST 
		def stock_out_by_shipment
			package_ids = Package.where(shipment_id: by_shipment_allowed_params[:shipment_id]).pluck(:id)

			res = StockOutByPackagesService.call(by_shipment_allowed_params.merge({package_ids: package_ids}))
	    if res.success?
	      render json: { "notice": "Opakowania zostały prawidłowo przypisane do Instytucji oraz zdjęte z magazynu." }, status: 200
	    else
	      @errors = res.error
	      render json: { "errors": @errors }, status: 500
	    end
		end

		# It is likely that this endpoint is not used by anyone.
		# {
		#    "shipment_id": 1
		# }
		# POST /api/stock_room/back_to_stock_by_shipment/:shipment_id
		def back_to_stock_by_shipment
			package_ids = Package.where(shipment_id: by_shipment_allowed_params[:shipment_id]).pluck(:id)

			res = BackToStockByPackagesService.call(by_shipment_allowed_params.merge({package_ids: package_ids}))
	    if res.success?
	      render json: { "notice": "Opakowania zostały prawidłowo zawrócone do magazynu." }, status: 200
	    else
	      @errors = res.error
	      render json: { "errors": @errors }, status: 500
	    end
		end


	private

		def by_packages_allowed_params
	    params.permit(:institution_id, :comment, package_ids: [])
	  end

	  def by_shipment_allowed_params
	    params.permit(:shipment_id, :institution_id, :comment)
	  end

	end
end