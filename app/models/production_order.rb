# == Schema Information
#
# Table name: production_orders
#
#  id                     :bigint           not null, primary key
#  lot                    :string(255)
#  packages_expiry_date   :datetime
#  packages_count         :integer
#  product_id             :bigint
#  stock_room_id          :bigint
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  comment                :text(65535)
#  sample_code_char_count :integer          default(5), not null
#
class ProductionOrder < ApplicationRecord
  belongs_to :product
  belongs_to :stock_room
  has_many :packages, dependent: :destroy
  has_many :reserved_sample_codes, through: :packages

  validates :packages_expiry_date, presence: true
  validates :packages_count, presence: true
  validates :lot, presence: true, uniqueness: true
  validates :packages_count, numericality: { only_integer: true }

  before_create :set_expiry_date_at_end_of_day

  private

  def set_expiry_date_at_end_of_day
    self.packages_expiry_date = self.packages_expiry_date.at_end_of_day
  end

end
