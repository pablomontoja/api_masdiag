# == Schema Information
#
# Table name: products
#
#  id               :bigint           not null, primary key
#  name             :string(255)
#  ref              :string(255)
#  type             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  capacity         :integer
#  material_type    :integer          default("dbs"), not null
#  material_handler :integer          default("dbs_t4"), not null
#
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
