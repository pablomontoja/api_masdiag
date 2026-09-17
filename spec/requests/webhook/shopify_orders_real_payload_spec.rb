require 'rails_helper'
require 'json'
require 'openssl'
require 'base64'

# Exercises the webhook with an actual Shopify test-mode order payload (captured
# from the store's "Order payment" webhook subscription, topic orders/paid),
# instead of a synthetic minimal body. Line items reference the store's real
# product_id values, which must match config/shopify_product_mappings.yml
# (LPC, 3-OMD, Amino, Acylcarnitines).
RSpec.describe 'Webhook::ShopifyOrdersController with a real Shopify payload', type: :request do
  let(:secret) { "test-shopify-secret" }

  def real_shopify_order_payload
    {
      "id" => 820_982_911_946_154_508,
      "test" => true,
      "currency" => "EUR",
      "total_discounts" => "20.00",
      "line_items" => [
        {
          "id" => 866_550_311_766_439_020,
          "name" => "Acylcarnitine Profile — Dried Blood Spot Test",
          "price" => "130.00",
          "product_id" => 15_592_369_881_418,
          "quantity" => 1,
          "variant_id" => 61_540_838_900_042
        },
        {
          "id" => 789_012_345_678_901_234,
          "name" => "Lens Protection Plan (2 Year)",
          "price" => "19.99",
          "product_id" => nil,
          "product_exists" => false,
          "quantity" => 1,
          "variant_id" => nil
        },
        {
          "id" => 890_123_456_789_012_345,
          "name" => "Premium Leather Case",
          "price" => "24.99",
          "product_id" => nil,
          "product_exists" => false,
          "quantity" => 1,
          "variant_id" => nil
        },
        {
          "id" => 141_249_953_214_522_974,
          "name" => "Amino Acid Profile — Dried Blood Spot Test",
          "price" => "70.00",
          "product_id" => 15_655_433_929_034,
          "quantity" => 1,
          "variant_id" => 61_821_976_019_274
        },
        {
          "id" => 257_004_973_105_704_598,
          "name" => "3-O-Methyldopa (3-OMD) — Dried Blood Spot Test",
          "price" => "60.00",
          "product_id" => 15_655_459_979_594,
          "quantity" => 1,
          "variant_id" => 61_822_064_918_858
        }
      ]
    }
  end

  def signature_for(raw_body, secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, raw_body))
  end

  def headers_for(raw_body, webhook_id:, topic: "orders/paid")
    {
      "Content-Type" => "application/json",
      "X-Shopify-Topic" => topic,
      "X-Shopify-Webhook-Id" => webhook_id,
      "X-Shopify-Hmac-SHA256" => signature_for(raw_body, secret)
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:shopify, :webhook_secret).and_return(secret)
  end

  it 'accepts the webhook and stores the raw payload as-is' do
    body = real_shopify_order_payload.to_json

    post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, webhook_id: "real-payload-1")

    expect(response).to have_http_status(:ok)
    expect(json["status"]).to eq("accepted")

    delivery = ShopifyOrderDelivery.find_by!(webhook_id: "real-payload-1")
    expect(delivery.shopify_order_id).to eq("820982911946154508")
    expect(delivery.payload["line_items"].size).to eq(5)
  end

  context 'when the mapped products in config/shopify_product_mappings.yml exist as LabSample Projects' do
    before do
      create(:project_without_fixed_id) { |p| p.update!(Id: 18) }  # Acylcarnitines -> product_id 15592369881418
      create(:project2)                                            # Amino          -> product_id 15655433929034 (Id 3)
      create(:project_without_fixed_id) { |p| p.update!(Id: 25) }  # 3-OMD          -> product_id 15655459979594
    end

    it 'blocks the order because two line items (add-ons) have no product_id at all' do
      body = real_shopify_order_payload.to_json
      post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, webhook_id: "real-payload-2")

      delivery = ShopifyOrderDelivery.find_by!(webhook_id: "real-payload-2")
      Shopify::OrderProcessor.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("blocked")
      expect(delivery.unmapped_product_ids).to eq(["", ""])
      expect(delivery.failure_reason).to be_present
    end

    it 'processes successfully once every line item carries a mapped product_id' do
      payload = real_shopify_order_payload
      payload["line_items"] = payload["line_items"].select { |item| item["product_id"].present? }
      body = payload.to_json

      post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, webhook_id: "real-payload-3")

      delivery = ShopifyOrderDelivery.find_by!(webhook_id: "real-payload-3")
      Shopify::OrderProcessor.call(delivery)
      delivery.reload

      expect(delivery.status).to eq("processed")
      expect(delivery.resolved_project_ids).to match_array([18, 3, 25])
      expect(delivery.unmapped_product_ids).to be_blank
    end
  end
end
