class Masdiag::PackagesCreator < ApplicationService
  attr_accessor :production_order

  def initialize(production_order)
    @production_order = production_order
  end

  def call
    begin
      # byebug
      last_serial = 0
      last_serial = Integer(Package.order(serial_number: :asc).last.serial_number)+1 if Package.order(serial_number: :asc).last.present?

      @production_order.packages_count.times {
        product = Product.find( @production_order.product_id )
        if product.type == 0  # same bibuły bez opakowań
          @production_order.packages.build(serial_number: nil,
                                           extended_serial_number: nil,
                                           expiry_date: @production_order.packages_expiry_date.at_end_of_day,
                                           product_id: @production_order.product_id,
                                           stock_room_id: @production_order.stock_room_id)
        else
          @production_order.packages.build(serial_number: last_serial,
                                           extended_serial_number: last_serial.to_s.rjust(6, "0"),
                                           expiry_date: @production_order.packages_expiry_date.at_end_of_day,
                                           product_id: @production_order.product_id,
                                           stock_room_id: @production_order.stock_room_id)
        end

        last_serial += 1
      }

      handle_result(@production_order)

    rescue Exception => e
      handle_error(e)
    end
  end

end
