# == Schema Information
#
# Table name: packages
#
#  id                     :bigint           not null, primary key
#  serial_number          :integer
#  extended_serial_number :string(255)
#  expiry_date            :datetime
#  product_id             :bigint           not null
#  production_order_id    :bigint
#  stock_room_id          :bigint
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  shipment_id            :integer
#  comment                :text(65535)
#  scan_time              :datetime
#
class Package < ApplicationRecord
	belongs_to :product
	has_many :reserved_sample_codes, class_name: "ReservedSampleCode", dependent: :nullify
	has_one :stock_room_item, as: :storagable, dependent: :destroy
	# belongs_to :production_order, optional: true

	validates :serial_number, uniqueness: true, allow_nil: true
	validates :extended_serial_number, uniqueness: true, allow_nil: true
end
