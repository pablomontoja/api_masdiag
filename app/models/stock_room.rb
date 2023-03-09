class StockRoom < ApplicationRecord
	has_many :packages
	has_many :production_orders
end
