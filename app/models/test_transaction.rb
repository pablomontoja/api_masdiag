# == Schema Information
#
# Table name: test_transactions
#
#  id                      :bigint           not null, primary key
#  amount_change           :integer          not null
#  project_id              :integer          not null
#  sample_id               :integer
#  contractor_id           :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  reserved_sample_code_id :integer
#
class TestTransaction < ApplicationRecord
  after_create :change_test_amount

  belongs_to :project
  belongs_to :sample, optional: true
  belongs_to :reserved_sample_code, optional: true
  belongs_to :contractor
  has_one :institution_order_component
  has_many :institution_tests, class_name: 'InstitutionTest'#, inverse_of: :test_transaction
  has_many :used_institution_tests, foreign_key: 'used_by_test_transaction_id', class_name: 'InstitutionTest', inverse_of: :used_by_test_transaction

  # accepts_nested_attributes_for :institution_tests

  validates :amount_change, presence: true
  validate :institution_tests_availability, if: proc { |it| it.amount_change.negative? }

  def remove_used_tests
    self.used_institution_tests.destroy_all
    # institution_tests = []
    # self.used_institution_tests.each do |t|
    #   institution_tests << { institution_id: self.contractor.institution_id, project_id: self.project_id,
    #                          expiry_date: calculate_test_expiry_date(t), created_at: Time.zone.now, updated_at: Time.zone.now, duplicate: true }
    # end

    # self.used_institution_tests.destroy_all if !institution_tests.size.zero?
    # self.institution_tests.insert_all(institution_tests) if !institution_tests.size.zero?
  end

  private

  def institution_tests_availability
    institution_id = self.contractor.institution.id
    if InstitutionTest.not_expired.not_used.where('project_id = ? AND institution_id = ?', self.project_id,
                                                  institution_id).count < self.amount_change.abs
      errors.add(:amount_change, '| not enough institution tests left in pool for such assignment')
    end
  end

  def change_test_amount
    change = self.amount_change
    if change.positive?
      institution_tests = []
      change.times do
        institution_tests << { institution_id: self.contractor.institution_id, project_id: self.project_id,
                               expiry_date: Time.zone.now + 2.years, created_at: Time.zone.now, updated_at: Time.zone.now }
      end
      self.institution_tests.insert_all(institution_tests)
    elsif change.negative?
      institution_id = self.contractor.institution.id
      InstitutionTest
      .not_expired
      .not_used
      .where(project_id: self.project_id, institution_id: institution_id)
      .order(expiry_date: :asc)
      .limit(change.abs)
      .update_all(used: true, used_by_test_transaction_id: self.id)
    end
  end

  # def readonly?
  #   true
  # end

  def calculate_test_expiry_date(old_test)
    old_expiry_date = old_test.expiry_date
    if old_expiry_date < Time.zone.today + 3.months
      Time.zone.today + 3.months + 1.day
    else
      old_expiry_date
    end
  end

end
