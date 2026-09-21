class AddShopOrderToShopifyOrderDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_reference :shopify_order_deliveries, :shop_order, null: true, foreign_key: true
  end
end
