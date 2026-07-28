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
#  snapshot_package_ids    :text(65535)
#  kits                    :text(65535)
#  coupons                 :text(65535)
#  total_cost              :decimal(7, 2)
#  total_cost_with_coupons :decimal(7, 2)
#
class ShopOrder < ApplicationRecord
	has_many :packages, dependent: :nullify
	has_many :reserved_sample_codes, through: :packages

	# package_ids/package_ids= come from has_many :packages (collection
	# association methods), not a DB column — unlike snapshot_package_ids,
	# which is the persisted point-in-time copy.
	serialize :snapshot_package_ids, type: Array, default: []
	serialize :kits, type: Array, default: []
  serialize :coupons, type: Array, default: []

	validates :number, uniqueness: true
	validates :email, presence: true
	# validate :check_package_ids

	before_destroy :clean_packages
	after_commit :link_packages, on: :create
	after_commit :update_snapshot_package_ids, on: :create

	def rscs
		# ReservedSampleCode.where(package_id: self.package_ids).all
		self.reserved_sample_codes
	end

	def costumer_fullname
		"#{self.first_name} #{self.last_name}"
	end

  def is_jps10?
    self.coupons.nil? ? false : self.coupons.any? {|c| c.code == "jps10"}
  end

private

	def update_snapshot_package_ids
    self.update(snapshot_package_ids: packages.pluck(:id))
  end

	# def check_package_ids
	# 	errors.add(:base, 'package_ids cannot be blank Array') if self.package_ids.blank?
	# end
	
	def link_packages
    return if self.package_ids.blank? || self.package_ids == "-"

    self.package_ids.each do |package_id|
      package = Package.find_by(id: package_id)
      if package
        package.update_column(:shop_order_id, self.id)
      else
        Sentry.capture_message("Warning: Package with id #{package_id} not found for ShopOrder ##{self.id}")
      end
    end
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
