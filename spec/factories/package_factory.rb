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

