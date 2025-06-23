# == Schema Information
#
# Table name: stock_rooms
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class StockRoom < ApplicationRecord
	has_many :packages
	has_many :production_orders
end
