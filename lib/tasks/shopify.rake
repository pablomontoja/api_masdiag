namespace :shopify do
  desc "Reprocess a blocked or failed Shopify order delivery by its webhook_id"
  task :reprocess_order_delivery, [:webhook_id] => :environment do |_t, args|
    delivery = ShopifyOrderDelivery.find_by!(webhook_id: args[:webhook_id])

    if delivery.processed?
      puts "Delivery #{delivery.webhook_id} is already processed — skipping."
      next
    end

    Shopify::ProcessOrderJob.perform_later(delivery.id)
    puts "Re-enqueued Shopify::ProcessOrderJob for delivery #{delivery.webhook_id}."
  end
end
