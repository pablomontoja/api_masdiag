module Shopify
  class OrderProcessor < ApplicationService
    def initialize(delivery)
      @delivery = delivery
    end

    def call
      line_items = @delivery.payload.fetch("line_items", [])
      resolved = {}
      unmapped = []

      line_items.each do |item|
        product_id = item["product_id"].to_s
        project_ids = Shopify::ProductMapper.project_ids_for(product_id)

        if project_ids.empty?
          unmapped << product_id
        else
          resolved[product_id] = project_ids
        end
      end

      if unmapped.any?
        block!(unmapped)
      else
        apply_discount(line_items)
        process!(resolved.values.flatten.uniq)
      end

      handle_result(@delivery)
    end

    private

    def block!(unmapped_product_ids)
      @delivery.update!(
        status: :blocked,
        unmapped_product_ids: unmapped_product_ids,
        resolved_project_ids: nil,
        failure_reason: "unmapped product(s): #{unmapped_product_ids.join(', ')}"
      )
    end

    def process!(resolved_project_ids)
      @delivery.update!(
        status: :processed,
        resolved_project_ids: resolved_project_ids,
        unmapped_product_ids: nil,
        failure_reason: nil,
        processed_at: Time.current
      )
    end

    # Mirrors ShopOrders::Product#price_discount_value's percentage-of-price
    # calculation (see app/models/shop_orders/product.rb) — applied here for
    # record-keeping/audit parity per spec FR-013, not to change what gets
    # mapped to which Project.
    def apply_discount(line_items)
      total_discount_percentage = @delivery.payload["total_discounts"].to_f
      return if total_discount_percentage.zero?

      line_items.each do |item|
        price = item["price"].to_f
        item["price_with_discount"] = (price - (total_discount_percentage * price) / 100.0).round(2)
      end
    end
  end
end
