module DiagnostykaPrecyzyjna
	class AppointmentBuilderService < ApplicationService
		attr_reader :appointment, :shop_product

		# Zarezerwowano od: 11 grudnia, 2023 17:30 | Zarezerwowano do: 11 grudnia, 2023 18:00 | Status rezerwacji: Opłacona

		def initialize(shop_order, shop_product)
			@shop_product = shop_product
			@appointment = { owner_email: shop_order.email, start_time: extract_start_time, end_time: extract_end_time, order_number: shop_order.number, phone_number: shop_order.phone }
		end

		def call
			@appointment
		end

	private

		def extract_start_time
			start_string = @shop_product.metadata.split("|").map(&:strip)[0]
			parse_datetime(start_string.split("od:").last)
		end

		def extract_end_time
			start_string = @shop_product.metadata.split("|").map(&:strip)[1]
			parse_datetime(start_string.split("do:").last)
		end

		def parse_datetime(str)
			Time.zone = "Warsaw"
			months = {["styczeń","stycznia"] => "Jan", ["luty", "lutego"] => "Feb", ["marzec", "marca"] => "Mar", ["kwiecień", "kwietnia"] => "Apr", ["maj", "maja"] => "May", ["czerwiec", "czerwca"] => "Jun", ["lipiec", "lipca"] => "Jul", ["sierpień", "sierpnia"] => "Aug", ["wrzesień", "września"] => "Sep", ["październik", "października"] => "Oct", ["listopad", "listopada"] => "Nov", ["grudzień", "grudnia"] => "Dec"}
			months.each do |polish_months, eng_month|
				polish_months.each do |pol_month|
					if str.match pol_month
						return Time.zone.parse( str.gsub!(/#{pol_month}/, eng_month) )
					end
				end			
			end
		end

	end
end