module Shopify
  class OrderProcessor < ApplicationService
    INSTITUTION_ID = 33

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
        allocate!(line_items, resolved)
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

    # Builds one Kit per unit of quantity (via Shopify::KitBuilder) and allocates a
    # Package/ReservedSampleCode per kit (via Shopify::RscAllocator), mirroring
    # DiagnostykaPrecyzyjna::RegShopOrder's prepare_ordered_kits/prepare_rsc pattern.
    # Any kit that fails to allocate rolls back the whole transaction (FR-006).
    def allocate!(line_items, resolved)
      items_with_project_ids = line_items.map { |item| item.merge("project_ids" => resolved.fetch(item["product_id"].to_s)) }
      kits = Shopify::KitBuilder.call(items_with_project_ids)

      shop_order = ShopOrder.new(shop_order_attributes(line_items))
      shortfall_project_ids = nil

      ActiveRecord::Base.transaction do
        shop_order.save!
        package_ids = []

        kits.each do |kit|
          rsc = Shopify::RscAllocator.call(kit.project_ids, { inst_id: INSTITUTION_ID })

          if rsc.nil?
            shortfall_project_ids = kit.project_ids
            raise ActiveRecord::Rollback
          end

          stock_room_out(rsc, shop_order)
          package_ids << rsc.package_id
        end

        shop_order.package_ids = package_ids
      end

      if shortfall_project_ids
        fail!(shortfall_project_ids)
      else
        process!(shop_order, resolved.values.flatten.uniq)
      end
    end

    # Field names/shape match Shopify's real orders/paid webhook payload (top-level
    # email/created_at, billing_address for name, customer for phone) — not WooCommerce's
    # flat billing_first_name/billing_email keys, which RegShopOrder's WordPress payload uses.
    def shop_order_attributes(line_items)
      payload = @delivery.payload
      billing_address = payload["billing_address"] || {}
      {
        source: "shopify",
        number: "shopify-#{@delivery.shopify_order_id}",
        time_signature: payload["created_at"],
        first_name: billing_address["first_name"] || payload.dig("customer", "first_name"),
        last_name: billing_address["last_name"] || payload.dig("customer", "last_name"),
        email: payload["email"] || payload.dig("customer", "email"),
        phone: payload.dig("customer", "phone") || payload["phone"],
        total_cost: total_cost(line_items),
        total_cost_with_coupons: total_cost_with_coupons(line_items)
      }
    end

    def total_cost(line_items)
      line_items.sum { |item| item["price"].to_f * item["quantity"].to_i }.round(2)
    end

    def total_cost_with_coupons(line_items)
      line_items.sum { |item| (item["price_with_discount"] || item["price"]).to_f * item["quantity"].to_i }.round(2)
    end

    def stock_room_out(rsc, shop_order)
      rsc.package.update!(comment: "Zamówienie sklepu Shopify (zamówienie - #{shop_order.number}, email zamawiającego - #{shop_order.email})")
      rsc.package.stock_room_item.update!(remaining_quantity: 0, date_out: Time.current)
    end

    def process!(shop_order, resolved_project_ids)
      @delivery.update!(
        status: :processed,
        shop_order: shop_order,
        resolved_project_ids: resolved_project_ids,
        unmapped_product_ids: nil,
        failure_reason: nil,
        processed_at: Time.current
      )
    end

    def fail!(shortfall_project_ids)
      @delivery.update!(
        status: :failed,
        shop_order: nil,
        resolved_project_ids: nil,
        failure_reason: "no inventory available for kit with project_ids: #{shortfall_project_ids.join(', ')}"
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
