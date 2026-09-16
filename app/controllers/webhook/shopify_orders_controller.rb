module Webhook
  class ShopifyOrdersController < ActionController::API
    include Response
    include ExceptionHandler

    before_action :verify_signature!
    before_action :verify_topic!

    # Secret lives at Rails.application.credentials.dig(:shopify, :webhook_secret)
    # (set via `bin/rails credentials:edit` — see specs/010-shopify-order-webhook/quickstart.md)
    def create
      raw_body = request.raw_post
      body = JSON.parse(raw_body)

      result = Shopify::OrderIngestor.call(
        webhook_id: request.headers["X-Shopify-Webhook-Id"],
        shopify_order_id: body["id"].to_s,
        payload: body
      )

      Shopify::ProcessOrderJob.perform_later(result.delivery.id) unless result.duplicate?

      json_response({ status: result.duplicate? ? "duplicate" : "accepted" }, :ok)
    rescue JSON::ParserError => e
      json_response({ error: e.message }, :unprocessable_content)
    end

    private

    def verify_signature!
      provided = request.headers["X-Shopify-Hmac-SHA256"].to_s
      secret = Rails.application.credentials.dig(:shopify, :webhook_secret).to_s
      raw_body = request.raw_post
      expected = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, raw_body))

      return if secret.present? && provided.present? &&
                ActiveSupport::SecurityUtils.secure_compare(provided, expected)

      json_response({ error: "invalid signature" }, :unauthorized)
    end

    def verify_topic!
      return if performed?
      return if request.headers["X-Shopify-Topic"] == "orders/create"

      json_response({ error: "unsupported topic" }, :unprocessable_content)
    end
  end
end
