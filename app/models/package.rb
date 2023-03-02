class Package < ApplicationRecord
	belongs_to :product
	has_many :reserved_sample_codes, class_name: "ReservedSampleCode", dependent: :nullify
	has_one :stock_room_item, as: :storagable, dependent: :destroy
	# belongs_to :production_order, optional: true

	validates :serial_number, uniqueness: true, allow_nil: true
	validates :extended_serial_number, uniqueness: true, allow_nil: true
end