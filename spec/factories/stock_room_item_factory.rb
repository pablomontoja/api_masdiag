# == Schema Information
#
# Table name: stock_room_items
#
#  id                        :bigint           not null, primary key
#  storagable_id             :bigint
#  storagable_type           :string(255)
#  capacity                  :integer
#  remaining_quantity        :integer
#  last_partial_consume_date :datetime
#  date_in                   :datetime
#  date_out                  :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  stock_room_id             :bigint
#
FactoryBot.define do
  factory :stock_room_item, class: StockRoomItem do
  	association :storagable, factory: :package
    association :stock_room
    capacity { 1 }
    remaining_quantity { 1 }
    last_partial_consume_date { nil }
    date_in { 1.month.ago }
    date_out { nil }
  end

  factory :second_stock_room_item, class: StockRoomItem do
    association :storagable, factory: :second_package
    association :stock_room
    capacity { 1 }
    remaining_quantity { 1 }
    last_partial_consume_date { nil }
    date_in { 1.month.ago }
    date_out { nil }
  end
end



# "storagable_id":"1230","storagable_type":"Package","capacity":"1","remaining_quantity":"1","last_partial_consume_date":null,"date_in":"2021-07-29 06:38:37","date_out":null,"created_at":"2021-07-29 06:38:37","updated_at":"2021-07-30 20:48:46","stock_room_id":"2"
