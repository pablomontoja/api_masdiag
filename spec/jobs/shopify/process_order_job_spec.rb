require 'rails_helper'

RSpec.describe Shopify::ProcessOrderJob, type: :job do
  let(:delivery) { create(:shopify_order_delivery) }

  it 'calls Shopify::OrderProcessor with the delivery' do
    expect(Shopify::OrderProcessor).to receive(:call).with(delivery)

    described_class.perform_now(delivery.id)
  end

  it 'marks the delivery failed when the processor raises (retry_on then handles the retry policy)' do
    allow(Shopify::OrderProcessor).to receive(:call).and_raise(StandardError, "boom")

    described_class.perform_now(delivery.id)

    delivery.reload
    expect(delivery.status).to eq("failed")
    expect(delivery.failure_reason).to eq("boom")
  end
end
