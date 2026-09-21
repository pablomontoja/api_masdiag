module Shopify
  class ProcessOrderJob < ApplicationJob
    queue_as :background

    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(delivery_id)
      delivery = ShopifyOrderDelivery.find(delivery_id)
      Shopify::OrderProcessor.call(delivery)
    rescue => e
      delivery&.update(status: :failed, failure_reason: e.message)
      raise
    end
  end
end
