# == Schema Information
#
# Table name: packages
#
#  id                     :bigint           not null, primary key
#  serial_number          :integer
#  extended_serial_number :string(255)
#  expiry_date            :datetime
#  product_id             :bigint           not null
#  production_order_id    :bigint
#  stock_room_id          :bigint
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  shipment_id            :integer
#  comment                :text(65535)
#  scan_time              :datetime
#
FactoryBot.define do
  factory :package, class: Package do
    serial_number { 1 }
    extended_serial_number { 000001 }
    expiry_date { 1.year.since }
    product
  end

  factory :second_package, class: Package do
    serial_number { 2 }
    extended_serial_number { 000002 }
    expiry_date { 1.year.since  }    
    association :product, factory: :second_product
  end
end

