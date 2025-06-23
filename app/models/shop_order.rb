# == Schema Information
#
# Table name: shop_orders
#
#  id                      :bigint           not null, primary key
#  number                  :string(255)
#  time_signature          :string(255)
#  first_name              :string(255)
#  last_name               :string(255)
#  email                   :string(255)
#  phone                   :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  package_ids             :text(65535)
#  kits                    :text(65535)
#  coupons                 :text(65535)
#  total_cost              :decimal(7, 2)
#  total_cost_with_coupons :decimal(7, 2)
#
class ShopOrder < ApplicationRecord
	serialize :package_ids, Array

	validates :number, uniqueness: true
	validates :email, presence: true
	validate :check_package_ids

	before_destroy :clean_packages

	def rscs
		ReservedSampleCode.where(package_id: self.package_ids).all
	end

	def costumer_fullname
		"#{self.first_name} #{self.last_name}"
	end

private

	def check_package_ids
		errors.add(:base, 'package_ids cannot be blank Array') if self.package_ids.blank?
	end

	def clean_packages
		self.rscs.each do |rsc|
			rsc.update(IsRetailSale: false, InstitutionId: nil)
			rsc.reserved_tests.destroy_all
			rsc.package.update(comment: nil)
			rsc.package.stock_room_item.update(remaining_quantity: 1, date_out: nil)
		end
	end
end
