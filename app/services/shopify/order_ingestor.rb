module Shopify
  class OrderIngestor < ApplicationService
    Result = Struct.new(:duplicate, :delivery, keyword_init: true) do
      def duplicate? = duplicate
    end

    def initialize(attrs)
      @webhook_id = attrs.fetch(:webhook_id)
      @shopify_order_id = attrs.fetch(:shopify_order_id)
      @payload = attrs.fetch(:payload)
      @event_type = attrs.fetch(:event_type, "orders/create")
    end

    def call
      existing = ShopifyOrderDelivery.find_by(webhook_id: @webhook_id)
      return Result.new(duplicate: true, delivery: existing) if existing

      delivery = ShopifyOrderDelivery.create!(
        webhook_id: @webhook_id,
        shopify_order_id: @shopify_order_id,
        payload: @payload,
        event_type: @event_type
      )
      Result.new(duplicate: false, delivery: delivery)
    rescue ActiveRecord::RecordNotUnique
      Result.new(duplicate: true, delivery: ShopifyOrderDelivery.find_by!(webhook_id: @webhook_id))
    end
  end
end
