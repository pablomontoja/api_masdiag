require 'rails_helper'

RSpec.describe Shopify::OrderProcessor do
  let(:mapping) { { "41234567890123" => [2], "41234567890124" => [3, 2] } }

  before do
    create(:project)  # Id 2
    create(:project2) # Id 3
    create(:institution, id: 33)
    allow(Shopify::ProductMapper).to receive(:mapping).and_return(mapping)
  end

  def payload_with(line_items:, total_discounts: "0.00")
    {
      "id" => 5_000_000_001,
      "email" => "customer@example.com",
      "created_at" => "2026-09-17T15:58:56+02:00",
      "billing_address" => { "first_name" => "Jan", "last_name" => "Kowalski" },
      "customer" => { "phone" => "+48123456789" },
      "line_items" => line_items,
      "total_discounts" => total_discounts
    }
  end

  # One in-stock Package/RSC per kit needed by the scenario under test, matching
  # Shopify::RscAllocator's eligibility query (default material_type/handler, since
  # Project ids 2/3 don't hit any of the special routing rules).
  def create_available_stock(count)
    product = create(:product)
    count.times do |i|
      package = create(:package, product: product, serial_number: 1000 + i, extended_serial_number: "S#{1000 + i}")
      create(:stock_room_item, storagable: package)
      create(:reserved_sample_code, package: package, IsRetailSale: false, InstitutionId: nil, Code: "STOCK#{1000 + i}")
    end
  end

  context 'when every line item is mapped' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(line_items: [
        { "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" },
        { "product_id" => "41234567890124", "quantity" => 1, "price" => "50.00" }
      ]))
    end

    before { create_available_stock(2) }

    it 'marks the delivery processed with the flattened, deduped Project ids' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
      expect(delivery.resolved_project_ids).to match_array([2, 3])
      expect(delivery.processed_at).to be_present
      expect(delivery.failure_reason).to be_nil
      expect(delivery.unmapped_product_ids).to be_blank
    end

    it 'creates a ShopOrder with one allocated Package per kit and correct Project groupings' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.shop_order).to be_present
      expect(delivery.shop_order.source).to eq("shopify")
      expect(delivery.shop_order.number).to eq("shopify-#{delivery.shopify_order_id}")
      expect(delivery.shop_order.packages.count).to eq(2)

      grouped = delivery.shop_order.reserved_sample_codes.map { |rsc| rsc.reserved_tests.pluck(:project_id).sort }
      expect(grouped).to contain_exactly([2], [2, 3])
    end

    it 'computes total_cost and total_cost_with_coupons from the line items' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.shop_order.total_cost).to eq(150.0)
      expect(delivery.shop_order.total_cost_with_coupons).to eq(150.0)
    end
  end

  context 'when one line item is unmapped among several mapped ones' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(line_items: [
        { "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" },
        { "product_id" => "00000000000000", "quantity" => 1, "price" => "10.00" }
      ]))
    end

    it 'blocks the entire order and lists the unmapped product, without partial processing' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("blocked")
      expect(delivery.unmapped_product_ids).to eq(["00000000000000"])
      expect(delivery.failure_reason).to be_present
      expect(delivery.resolved_project_ids).to be_blank
    end

    it 'creates no ShopOrder at all (allocation never attempted)' do
      shop_order_count = ShopOrder.count

      described_class.call(delivery)
      delivery.reload

      expect(delivery.shop_order).to be_nil
      expect(ShopOrder.count).to eq(shop_order_count)
    end
  end

  context 'when a percentage discount is present' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(
        line_items: [{ "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" }],
        total_discounts: "10.00"
      ))
    end

    before { create_available_stock(1) }

    it 'is still processed successfully (discount applied per FR-013)' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
    end

    it 'reflects the discounted price on total_cost_with_coupons' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.shop_order.total_cost).to eq(100.0)
      expect(delivery.shop_order.total_cost_with_coupons).to eq(90.0)
    end
  end

  context 'when inventory is insufficient for one of the kits (User Story 2)' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(line_items: [
        { "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" },
        { "product_id" => "41234567890124", "quantity" => 1, "price" => "50.00" }
      ]))
    end

    before { create_available_stock(1) } # only 1 in stock, but 2 kits are needed

    it 'marks the delivery failed and leaves no ShopOrder/allocation behind' do
      shop_order_count = ShopOrder.count
      rsc_reserved_count = ReservedSampleCode.where(IsRetailSale: true).count

      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("failed")
      expect(delivery.shop_order).to be_nil
      expect(delivery.failure_reason).to be_present
      expect(delivery.resolved_project_ids).to be_blank
      expect(ShopOrder.count).to eq(shop_order_count)
      expect(ReservedSampleCode.where(IsRetailSale: true).count).to eq(rsc_reserved_count)
    end
  end

  context 'reprocessing (User Story 3)' do
    it 're-resolves a blocked delivery to processed after the mapping is fixed' do
      create_available_stock(1)
      delivery = create(:shopify_order_delivery, status: :blocked,
        failure_reason: "unmapped product: 00000000000000",
        unmapped_product_ids: ["00000000000000"],
        payload: payload_with(line_items: [
          { "product_id" => "00000000000000", "quantity" => 1, "price" => "10.00" }
        ]))
      allow(Shopify::ProductMapper).to receive(:mapping).and_return({ "00000000000000" => [2] })

      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
      expect(delivery.failure_reason).to be_nil
      expect(delivery.unmapped_product_ids).to be_blank
      expect(delivery.resolved_project_ids).to eq([2])
    end

    it 're-resolves a failed delivery to processed once the underlying issue is fixed' do
      create_available_stock(1)
      delivery = create(:shopify_order_delivery, status: :failed,
        failure_reason: "boom",
        payload: payload_with(line_items: [
          { "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" }
        ]))

      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
      expect(delivery.failure_reason).to be_nil
    end
  end
end
