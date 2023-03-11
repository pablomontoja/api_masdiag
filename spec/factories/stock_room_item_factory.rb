FactoryBot.define do
  factory :stock_room_item, class: StockRoomItem do
  	association :storagable, factory: :package
    capacity { 1 }
    remaining_quantity { 1 }
    last_partial_consume_date { nil }
    date_in { 1.month.ago }
    date_out { nil }
    stock_room_id { 1 }
  end

  factory :second_stock_room_item, class: StockRoomItem do
    association :storagable, factory: :second_package
    capacity { 1 }
    remaining_quantity { 1 }
    last_partial_consume_date { nil }
    date_in { 1.month.ago }
    date_out { nil }
    stock_room_id { 1 }
  end
end



# "storagable_id":"1230","storagable_type":"Package","capacity":"1","remaining_quantity":"1","last_partial_consume_date":null,"date_in":"2021-07-29 06:38:37","date_out":null,"created_at":"2021-07-29 06:38:37","updated_at":"2021-07-30 20:48:46","stock_room_id":"2"