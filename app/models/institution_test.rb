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
