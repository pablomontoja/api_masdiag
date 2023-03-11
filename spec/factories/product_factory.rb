FactoryBot.define do
  factory :product, class: Product do
    name { "Pudełko Diagnostyki Precyzyjnej" }
    ref { "Pudełko Diagnostyki Precyzyjnej" }
    type { 1 }
    capacity { 1 }
  end

  factory :second_product, class: Product do
    name { "Pudełko Diagnostyki Precyzyjnej ver 2" }
    ref { "Pudełko Diagnostyki Precyzyjnej ver 2" }
    type { 1 }
    capacity { 1 }
  end
end

# "id":"1"
# "name":"Pudełko Diagnostyki Precyzyjnej"
# "ref":"MSD.001.01.DP.U"
# "type":"1"
# "created_at":"2021-07-29 06:34:46"
# "updated_at":"2021-07-29 06:34:46"
# "capacity":"1"