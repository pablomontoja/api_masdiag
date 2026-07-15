# == Schema Information
#
# Table name: tests
#
#  id                     :bigint           not null, primary key
#  name                   :string(255)
#  acronym                :string(255)
#  name_in_invoice        :string(255)
#  project_id             :integer
#  default_price_cents    :integer          default(0), not null
#  default_price_currency :string(255)      default("PLN"), not null
#  material_type          :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  vat_rate               :integer          default(0)
#
class Test < ApplicationRecord
  monetize :default_price_cents,
            numericality: { greater_than_or_equal_to: 0 }

  belongs_to :project, optional: true
  has_many :tests_prices
  has_many :institutions, through: :tests_prices

  validates :project, uniqueness: {scope: :material_type}

  enum material_type: MaterialTypes::MODEL_HASH
end
