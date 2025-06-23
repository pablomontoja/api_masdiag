# == Schema Information
#
# Table name: institution_tests
#
#  id                          :bigint           not null, primary key
#  institution_id              :integer          not null
#  project_id                  :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  expiry_date                 :datetime
#  test_transaction_id         :integer
#  used                        :boolean          default(FALSE)
#  used_by_test_transaction_id :integer
#  duplicate                   :boolean          default(FALSE)
#
class InstitutionTest < ApplicationRecord
  belongs_to :institution
  belongs_to :project
  belongs_to :test_transaction, class_name: 'TestTransaction'
  belongs_to :used_by_test_transaction, class_name: 'TestTransaction'

  validates :expiry_date, presence: true

  scope :not_expired, -> { where('expiry_date > ?', Time.zone.today) }
  scope :not_used, -> { where(used: false) }

  # def readonly?
  #   true
  # end

end
