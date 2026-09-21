require 'rails_helper'

RSpec.describe Shopify::OrderIngestor do
  let(:payload) { { "id" => 5_000_000_001, "line_items" => [] } }

  it 'persists a new delivery with the raw payload' do
    result = described_class.call(webhook_id: "wh-1", shopify_order_id: "5000000001", payload: payload)

    expect(result.duplicate?).to eq(false)
    expect(result.delivery).to be_persisted
    expect(result.delivery.payload).to eq(payload)
    expect(result.delivery.status).to eq("pending")
  end

  it 'returns the existing record without creating a duplicate for the same webhook_id' do
    existing = create(:shopify_order_delivery, webhook_id: "wh-2")

    result = described_class.call(webhook_id: "wh-2", shopify_order_id: "5000000002", payload: payload)

    expect(result.duplicate?).to eq(true)
    expect(result.delivery).to eq(existing)
    expect(ShopifyOrderDelivery.where(webhook_id: "wh-2").count).to eq(1)
  end

  it 'handles a concurrent duplicate insert race via RecordNotUnique' do
    existing = create(:shopify_order_delivery, webhook_id: "wh-3")

    allow(ShopifyOrderDelivery).to receive(:find_by).and_return(nil)
    allow(ShopifyOrderDelivery).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
    allow(ShopifyOrderDelivery).to receive(:find_by!).and_return(existing)

    result = described_class.call(webhook_id: "wh-3", shopify_order_id: "5000000003", payload: payload)

    expect(result.duplicate?).to eq(true)
    expect(result.delivery).to eq(existing)
  end
end
