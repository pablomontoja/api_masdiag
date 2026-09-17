require 'rails_helper'

RSpec.describe Shopify::OrderProcessor do
  let(:mapping) { { "41234567890123" => [2], "41234567890124" => [3, 2] } }

  before do
    create(:project)  # Id 2
    create(:project2) # Id 3
    allow(Shopify::ProductMapper).to receive(:mapping).and_return(mapping)
  end

  def payload_with(line_items:, total_discounts: "0.00")
    {
      "id" => 5_000_000_001,
      "line_items" => line_items,
      "total_discounts" => total_discounts
    }
  end

  context 'when every line item is mapped' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(line_items: [
        { "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" },
        { "product_id" => "41234567890124", "quantity" => 1, "price" => "50.00" }
      ]))
    end

    it 'marks the delivery processed with the flattened, deduped Project ids' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
      expect(delivery.resolved_project_ids).to match_array([2, 3])
      expect(delivery.processed_at).to be_present
      expect(delivery.failure_reason).to be_nil
      expect(delivery.unmapped_product_ids).to be_blank
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
  end

  context 'when a percentage discount is present' do
    let(:delivery) do
      create(:shopify_order_delivery, payload: payload_with(
        line_items: [{ "product_id" => "41234567890123", "quantity" => 1, "price" => "100.00" }],
        total_discounts: "10.00"
      ))
    end

    it 'is still processed successfully (discount applied per FR-013)' do
      described_class.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
    end
  end

  context 'reprocessing (User Story 3)' do
    it 're-resolves a blocked delivery to processed after the mapping is fixed' do
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
