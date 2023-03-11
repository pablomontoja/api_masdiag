FactoryBot.define do
  factory :shop_order, class: ShopOrder do
    number { Faker::Number.non_zero_digit }
    time_signature { "2022-01-07 15:32" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone }
  end
end


# "id":"517"
# "number":"9592"
# "time_signature":"2022-01-07 15:32"
# "first_name":"Paulina"
# "last_name":"Majchrowska"
# "email":"paulinamajchrowska@op.pl"
# "phone":"531240762"
# "created_at":"2022-01-10 08:24:14"
# "updated_at":"2022-01-10 08:24:14"