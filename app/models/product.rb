class Product < ApplicationRecord
	has_many :packages
	has_many :production_orders
	
	self.inheritance_column = :_type_disabled_bla_bla

	validates :name, presence: true, uniqueness: true
	validates :ref, presence: true, uniqueness: true
	validates :type, presence: true
	validates :capacity, presence: true, numericality: { only_integer: true }


	def fullname
		"#{self.name} - #{self.ref}"
	end

	def readonly?
    Rails.env.test? ? false : true
  end
end
