module MasdiagRecurring
  class MonthlyJps10RaportMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail
      prev_month_begin = (DateTime.now - 1.month).beginning_of_month
      prev_month_end = (DateTime.now - 1.month).end_of_month

      shop_orders = ShopOrder.where(created_at: prev_month_begin..prev_month_end).all.select{|s| s.is_jps10? }

      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: "JPS10 Raport #{ Date.today.strftime('%Y-%m') }") do |sheet|
        # Add header row
        sheet.add_row ["Lp.", "Nr zamówienia", "Zestaw", "szt.", "Koszt zestawu po zniżkach PLN", "jps%", "jps prowizja PLN"]
        
        idx = 1
        shop_orders.each do |sorder|
          sorder.kits.each do |k|
            sheet.add_row [
              idx, 
              sorder.number, 
              k.products.map{|pr| pr.name}.join(", "), 
              k.quantity, 
              k.cost_with_discount, 
              perc_fee(k), 
              fee(k)
            ]
            idx += 1
          end
        end
      end

      # package.serialize("tmp/jps10.xlsx")

      stream = package.to_stream
      attachments["jps10-#{ Date.today.strftime('%Y-%m') }.xlsx"] = stream.read

      mail(to: 'anna.grabowska@masdiag.pl', cc: "pawel.swider@masdiag.pl", subject: "JPS10 #{ Date.today.strftime('%Y-%m') }")
    end


  private

    def perc_fee(kit)
      res = 10
      res = 20 if (kit.project_ids & [15, 18, 21]).any?
      return res
    end

    def fee(kit)
      (perc_fee(kit)*kit.cost_with_discount)/100.0
    end


  end
end