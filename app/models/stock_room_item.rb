class StockRoomItem < ApplicationRecord
  belongs_to :storagable, polymorphic: true
  # belongs_to :stock_room

  scope :is_in, -> { where("remaining_quantity > 0", date_out: nil) }
  scope :is_out, -> { where(remaining_quantity: 0).where.not(date_out: nil) }
  scope :only_packages, -> { where(storagable_type: Package)}
end