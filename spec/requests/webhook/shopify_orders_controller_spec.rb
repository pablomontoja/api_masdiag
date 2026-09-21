require 'rails_helper'
require 'json'
require 'openssl'
require 'base64'

RSpec.describe 'Webhook::ShopifyOrdersController', type: :request do
  let(:secret) { "test-shopify-secret" }
  let(:body) do
    {
      id: 5_000_000_001,
      line_items: [
        { product_id: 15_592_369_881_418, quantity: 1, price: "100.00" }
      ]
    }.to_json
  end

  def signature_for(raw_body, secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, raw_body))
  end

  def headers_for(raw_body, webhook_id: "delivery-1", topic: "orders/paid", secret: nil)
    {
      "Content-Type" => "application/json",
      "X-Shopify-Topic" => topic,
      "X-Shopify-Webhook-Id" => webhook_id,
      "X-Shopify-Hmac-SHA256" => secret ? signature_for(raw_body, secret) : "invalid-signature"
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:shopify, :webhook_secret).and_return(secret)
  end

  describe 'POST /webhook/shopify/orders_create' do
    context 'with a valid signature' do
      it 'accepts the delivery and returns 200' do
        post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, secret: secret)

        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("accepted")
      end

      it 'creates exactly one ShopifyOrderDelivery' do
        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, secret: secret)
        }.to change(ShopifyOrderDelivery, :count).by(1)
      end

      it 'enqueues Shopify::ProcessOrderJob exactly once' do
        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, secret: secret)
        }.to have_enqueued_job(Shopify::ProcessOrderJob)
      end
    end

    context 'when the same X-Shopify-Webhook-Id is delivered twice' do
      it 'returns duplicate on the second delivery without creating a second row' do
        headers = headers_for(body, webhook_id: "delivery-dup", secret: secret)
        post '/webhook/shopify/orders_create', params: body, headers: headers

        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers
        }.not_to change(ShopifyOrderDelivery, :count)

        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("duplicate")
      end

      it 'does not re-enqueue Shopify::ProcessOrderJob on the duplicate' do
        headers = headers_for(body, webhook_id: "delivery-dup-2", secret: secret)
        post '/webhook/shopify/orders_create', params: body, headers: headers

        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers
        }.not_to have_enqueued_job(Shopify::ProcessOrderJob)
      end
    end

    context 'with an invalid signature' do
      it 'returns 401 and creates no record' do
        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, secret: nil)
        }.not_to change(ShopifyOrderDelivery, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without an X-Shopify-Hmac-SHA256 header' do
      it 'returns 401' do
        headers = headers_for(body, secret: secret)
        headers.delete("X-Shopify-Hmac-SHA256")

        post '/webhook/shopify/orders_create', params: body, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with an unsupported topic' do
      it 'returns 422 and creates no record' do
        expect {
          post '/webhook/shopify/orders_create', params: body, headers: headers_for(body, topic: "orders/create", secret: secret)
        }.not_to change(ShopifyOrderDelivery, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
