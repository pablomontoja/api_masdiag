module MasdiagMailer
	class IndMailerPreview < ActionMailer::Preview
		
		def after_new_order_save
			shop_order_id = ShopOrder.wordpress_sourced.last(100).pluck(:id).sample
			MasdiagMailer::IndMailer.after_new_order_save(shop_order_id)
		end

		def after_new_order_save_shopify
			shop_order_id = ShopOrder.shopify_sourced.last(100).pluck(:id).sample
			MasdiagMailer::IndMailer.after_new_order_save(shop_order_id)
		end

		def shipping_after_new_order
			shop_order_id = ShopOrder.last(100).pluck(:id).sample
			MasdiagMailer::IndMailer.shipping_after_new_order(shop_order_id)
		end
		
	end
end