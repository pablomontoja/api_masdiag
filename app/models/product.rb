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
#  material_type    :integer          default(0), not null
#  material_handler :integer          default(0), not null
#
class Product < ApplicationRecord
	has_many :packages
	has_many :production_orders
	
	self.inheritance_column = :_type_disabled_bla_bla
	enum :material_type, MaterialTypes::MODEL_HASH
	enum :material_handler, MaterialHandlers::MODEL_HASH

	before_save :set_material_type

	validates :name, presence: true, uniqueness: true
	validates :ref, presence: true, uniqueness: true
	validates :type, presence: true
	validates :capacity, presence: true, numericality: { only_integer: true }


	def fullname
		"#{self.name} - #{self.ref}"
	end

	private

	def set_material_type
		self.material_type = MaterialHandlers::MATERIAL_TYPE[self.material_handler.to_sym] || :dbs
	end

	def readonly?
    Rails.env.test? ? false : true
  end
end

