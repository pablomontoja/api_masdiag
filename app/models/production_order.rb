class ProductionOrder < ApplicationRecord
  belongs_to :product
  belongs_to :stock_room
  has_many :packages, dependent: :destroy
  has_many :reserved_sample_codes, through: :packages

  validates :packages_expiry_date, presence: true
  validates :packages_count, presence: true
  validates :lot, presence: true, uniqueness: true
  validates :packages_count, numericality: { only_integer: true }
  validates :material_type, numericality: { only_integer: true }, presence: true

  # enum :material_type, { capillary_blood: 0, blood_serum: 1, blood_plasma: 2, hair: 3, nails: 4, urine: 5, saliva: 6 }

  before_create :set_expiry_date_at_end_of_day


  private

  def set_expiry_date_at_end_of_day
    self.packages_expiry_date = self.packages_expiry_date.at_end_of_day
  end

end
