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
class StockRoomItem < ApplicationRecord
  belongs_to :storagable, polymorphic: true
  # belongs_to :stock_room

  scope :is_in, -> { where("remaining_quantity > 0", date_out: nil) }
  scope :is_out, -> { where(remaining_quantity: 0).where.not(date_out: nil) }
  scope :only_packages, -> { where(storagable_type: Package)}
end
