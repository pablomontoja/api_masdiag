FactoryBot.define do
  factory :shopify_order_delivery, class: ShopifyOrderDelivery do
    sequence(:webhook_id) { |n| "webhook-#{n}" }
    shopify_order_id { "5000000000#{rand(100)}" }
    event_type { "orders/create" }
    payload do
      {
        "id" => shopify_order_id,
        "line_items" => [
          { "variant_id" => "41234567890123", "quantity" => 1, "price" => "100.00" }
        ]
      }
    end
    status { :pending }
  end
end
