class ShopOrder < ApplicationRecord
	serialize :package_ids, type: Array

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
