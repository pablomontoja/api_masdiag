module ShopOrders
  class Product
    require 'sanitize'
    attr_reader :product_hash, :name, :price, :project_ids, :is_nested, :coupons, :metadata

    def initialize(product_hash, coupons, is_nested = false)
      @coupons = coupons
      @product_hash = product_hash
      @is_nested = is_nested
      @project_ids = []
      @metadata = nil
    end

    def call
      if @is_nested
        extract_nested()
      else
        extract()
      end
      project_ids.flatten!
      OpenStruct.new({name: name, price: price, project_ids: project_ids, price_with_discount: price_discount_value, metadata: metadata})
    end

    private

    def price_discount_value
      discount = (coupons.sum(&:percentage)*price)/100.0
      (price - discount).round(0)
    end

    def extract
      @name = @product_hash["Product Name (main)"]
      @price = BigDecimal(@product_hash["Product Current Price"] || "0")
      @project_ids << decode_project(@name)
      @metadata = @product_hash.fetch("Order Item Metadata", nil)
    end

    def extract_nested
      @name = Sanitize.fragment(@product_hash["value"].force_encoding('UTF-8'))
      @price = BigDecimal(@product_hash["price"].to_s)
      @project_ids << decode_project(@name)
    end

    def decode_project(txt)
      case txt
      when "Badanie stężenia homocysteiny i witaminy D (Nordic Walking)"
        return [2, 12]
      when "Badanie stężenia 3-O-metylodopy i witaminy D"
        return [25, 2]
      when "Badanie stężenia 3-O-metylodopy i profilu aminokwasów"
        return [25, 3]
      when "Badanie stężenia 3-O-metylodopy i Homocysteiny"
        return [25, 12]
      when "Badanie stężenia 3-O-metylodopy i profilu acylokarnityn"
        return [25, 18]
      when "Badanie stężenia 3-O-metylodopy"
        return 25
      when "Badanie profilu acylokarnityn i aminokwasów"
        return [18, 3]
      when "Badanie profilu acylokarnityn i stężenia witaminy D"
        return [18, 2]
      when "Badanie profilu acylokarnityn i stężenia homocysteiny"
        return [18, 12]
      when "Badanie profilu aminokwasów i stężenia witaminy D"
        return [3, 2]
      when "Badanie stężenia homocysteiny i witaminy D"
        return [12, 2]
      when "Badanie profilu aminokwasów i stężenia homocysteiny"
        return [3, 12]
      when "Badanie profilu kwasów organicznych, profilu puryn i pirymidyn, obecności SAICAr, S-Ado i AICAR"
        return [15, 16, 17]
      when "Badanie toksykologiczne moczu"
        return 31
      when "Badanie poziomu Witaminy D", "Badanie stężenia witaminy D", "Witamina D"
        return 2
      when /^.*(?=.*Badanie profilu aminokwasów).*$/
        return 3
      when /^.*(?=.*Profil aminokwasów).*$/
        return 3
      when "Badanie stężenia CBD"
        Sentry.capture_message("Zamówiono test CBD w sklepie diagnostykaprecyzyjna.pl")
        MasdiagMailer::IndMailer.after_error(["IndClients2","RegShopOrder","Zamówiono test CBD w sklepie diagnostykaprecyzyjna.pl" ]).deliver_later
        return 11
      when "Badanie nietolerancji histaminy (DAO)"
        Sentry.capture_message("Zamówiono test DAO w sklepie diagnostykaprecyzyjna.pl")
        MasdiagMailer::IndMailer.after_error(["IndClients2","RegShopOrder","Zamówiono test DAO w sklepie diagnostykaprecyzyjna.pl" ]).deliver_later
        return 24
      when "Przeciwciała anty-SARS-CoV-2"
        return 9
      when "Pakiet odpornościowy - Wit. D i przeciwciała anty-SARS-CoV-2"
        return [2, 9]
      when "Badanie stężenia homocysteiny"
        return 12
      when "Badanie stężenia TSH"
        return 14
      when "Badanie obecności substancji psychoaktywnych"
        return [7, 11]
      when "Badanie profilu kwasów organicznych"
        return 15
      when "Badanie profilu puryn i pirymidyn"
        return 16
      when "Badanie obecności SAICAr, S-Ado i AICAR"
        return 17
      when "Profilu kwasów organicznych, puryn i pirymidyn oraz SAICAr i S-Ado w moczu"
        return [15, 16, 17]
      when /^.*(?=.*Badanie profilu puryn i pirymidyn)(?=.*Badanie obecności SAICAr, S-Ado i AICAR).*$/
        return [16, 17]
      when /^.*(?=.*Badanie profilu kwasów organicznych)(?=.*Badanie obecności SAICAr, S-Ado i AICAR).*$/
        return [15, 17]
      when /^.*(?=.*Badanie profilu kwasów organicznych)(?=.*Badanie profilu puryn i pirymidyn).*$/
        return [15, 16]
      when /^.*(?=.*Aminokwasy i Acylokarnityny).*$/
        return [3, 18]
      when "Badanie profilu acylokarnityn", "Badanie profilu karnityny i jej estrów – acylokarnityn", "Badanie profilu karnityny i jej estrów - acylokarnityn"
        return [18]
      when /^.*(?=.*Omega test).*$/
        return [21]
      when /^.*(?=.*Konsultacja).*$/
        return [0]
      else
        Sentry.capture_message("Nie można rozpoznać typu badania na podstawie danych przesłanych ze sklepu diagnostykaprecyzyjna.pl.")
        MasdiagMailer::IndMailer.after_error(["IndClients2","RegShopOrder","Nie można rozpoznać typu badania na podstawie danych przesłanych ze sklepu diagnostykaprecyzyjna.pl.", txt ]).deliver_later
        return []
      end
    end

  end
end

