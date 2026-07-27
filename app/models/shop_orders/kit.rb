module ShopOrders
  class Kit
    attr_reader :product_hash, :cost, :cost_with_discount, :quantity, :project_ids, :products, :coupons

    def initialize(product_hash, coupons)
      @coupons = coupons
      @product_hash = product_hash
      @cost = 0.0
      @cost_with_discount = 0.0
      @quantity = 0
      @project_ids = []
      @products = []
    end

    def call
      quantity = Integer(product_hash["Quantity"], 10)

      products << ShopOrders::Product.new(product_hash, coupons).call
      if product_hash["_tmcartepo_data"].present?
        pr = PHP.unserialize(product_hash["_tmcartepo_data"])
        products << ShopOrders::Product.new(pr[0], coupons, true).call
      end

      cost = products.sum {|pr| pr.price} * quantity
      cost_with_discount = products.sum {|pr| pr.price_with_discount} * quantity
      products.each{|pr| project_ids << pr.project_ids}
      project_ids.flatten!

      OpenStruct.new({cost: cost, quantity: quantity, project_ids: project_ids, products: products, cost_with_discount: cost_with_discount})
    end

    # def to_h
    #   hash = {}
    #   self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
    #   hash
    # end
  end
end
