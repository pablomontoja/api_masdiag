class CreateShopifyOrderDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :shopify_order_deliveries, charset: "utf8mb4" do |t|
      t.string   :webhook_id,            null: false
      t.string   :shopify_order_id,      null: false
      t.string   :event_type,            null: false, default: "orders/paid"
      t.text     :payload,               null: false, limit: 16.megabytes - 1
      t.integer  :status,                null: false, default: 0
      t.text     :failure_reason
      t.text     :unmapped_product_ids
      t.text     :resolved_project_ids
      t.datetime :processed_at
      t.timestamps
    end

    add_index :shopify_order_deliveries, :webhook_id, unique: true
    add_index :shopify_order_deliveries, :shopify_order_id
    add_index :shopify_order_deliveries, :status
  end
end
