# == Schema Information
#
# Table name: tests_prices
#
#  id             :bigint           not null, primary key
#  test_id        :bigint           not null
#  institution_id :integer          not null
#  price_cents    :integer          default(0), not null
#  price_currency :string(255)      default("PLN"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class TestsPrice < ApplicationRecord
   validates :test_id, uniqueness: { scope: :institution_id }

   monetize :price_cents,
            numericality: { greater_than_or_equal_to: 0 }
   
   belongs_to :institution
   belongs_to :test
end
