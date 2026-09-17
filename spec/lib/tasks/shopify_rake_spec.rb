require 'rails_helper'
require 'rake'

RSpec.describe 'shopify:reprocess_order_delivery' do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['shopify:reprocess_order_delivery'].reenable
  end

  it 're-enqueues Shopify::ProcessOrderJob for a blocked delivery' do
    delivery = create(:shopify_order_delivery, status: :blocked, webhook_id: "wh-reprocess-1")

    expect {
      Rake::Task['shopify:reprocess_order_delivery'].invoke("wh-reprocess-1")
    }.to have_enqueued_job(Shopify::ProcessOrderJob).with(delivery.id)
  end

  it 'is a no-op for an already processed delivery' do
    create(:shopify_order_delivery, status: :processed, webhook_id: "wh-reprocess-2")

    expect {
      Rake::Task['shopify:reprocess_order_delivery'].invoke("wh-reprocess-2")
    }.not_to have_enqueued_job(Shopify::ProcessOrderJob)
  end

  it 're-enqueues Shopify::ProcessOrderJob for a failed delivery (inventory shortfall, per US2)' do
    delivery = create(:shopify_order_delivery, status: :failed, webhook_id: "wh-reprocess-3",
      failure_reason: "no inventory available for kit with project_ids: 2")

    expect {
      Rake::Task['shopify:reprocess_order_delivery'].invoke("wh-reprocess-3")
    }.to have_enqueued_job(Shopify::ProcessOrderJob).with(delivery.id)
  end
end
