module ShopOrders
  class MixedKits
    attr_reader :shop_kit, :coupons

    def initialize(shop_kit, coupons)
      @coupons = coupons
      @shop_kit = shop_kit
    end

    def call
      kits = []

      case shop_kit["Product Name (main)"]
      when /^.*(?=.*Pakiet Metaboliczny).*$/
        shop_kit["Product Name (main)"] = "Aminokwasy i Acylokarnityny"
        shop_kit["Product Current Price"] = "607"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call

        shop_kit["Product Name (main)"] = "Badanie profilu kwasów organicznych"
        shop_kit["Product Current Price"] = "393"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call
      when /^.*(?=.*Pakiet metaboliczny).*$/
        shop_kit["Product Name (main)"] = "Aminokwasy i Acylokarnityny"
        shop_kit["Product Current Price"] = "607"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call

        shop_kit["Product Name (main)"] = "Badanie profilu kwasów organicznych"
        shop_kit["Product Current Price"] = "393"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call
      when /^.*(?=.*Rozszerzony pakiet metaboliczny).*$/
        shop_kit["Product Name (main)"] = "Aminokwasy i Acylokarnityny"
        shop_kit["Product Current Price"] = "607"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call

        shop_kit["Product Name (main)"] = "Profilu kwasów organicznych, puryn i pirymidyn oraz SAICAr i S-Ado w moczu"
        shop_kit["Product Current Price"] = "893"
        kits << ShopOrders::Kit.new(shop_kit, coupons).call
      end

      kits
    end

    # def to_h
    #   hash = {}
    #   self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
    #   hash
    # end
  end
end

