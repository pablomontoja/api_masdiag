module ShopOrders
  class Coupon
    attr_reader :coupon_hash, :code, :percentage, :discount_amount

    def initialize(coupon_hash)
      @coupon_hash = coupon_hash
    end

    def call
      code = coupon_hash["Coupon Code"]
      percentage = BigDecimal(coupon_hash["Coupon Amount"])
      discount_amount = Integer(coupon_hash["Discount Amount"], 10)

      OpenStruct.new({code: code, percentage: percentage, discount_amount: discount_amount})
    end
  end
end
