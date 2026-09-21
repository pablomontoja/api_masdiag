require "rails_helper"

RSpec.describe ShopOrder, type: :model do
  describe "#destroy" do
    it "nullifies shop_order_id on linked ShopifyOrderDeliveries instead of raising a foreign key error" do
      shop_order = create(:shop_order, source: "shopify")
      delivery = create(:shopify_order_delivery, shop_order: shop_order, status: :processed)

      expect { shop_order.destroy }.not_to raise_error
      expect(delivery.reload.shop_order_id).to be_nil
    end
  end
end
