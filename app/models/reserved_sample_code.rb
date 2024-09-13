class ReservedSampleCode < ApplicationRecord
  self.table_name = "ReservedSampleCodes"
  self.primary_key = "Id"

  enum :material_handler, MaterialHandlers::MODEL_HASH
  enum :MaterialType, MaterialTypes::MODEL_HASH

  belongs_to :package, optional: true
  belongs_to :institution, class_name: "Institution", foreign_key: "InstitutionId", optional: true
  # belongs_to :project, class_name: "Project", foreign_key: "ProjectId", optional: true
  has_many :reserved_tests
  has_many :projects, through: :reserved_tests
  has_many :test_transactions
  belongs_to :reserved_by, foreign_key: :reserved_by_contractor_id, class_name: "Contractor", optional: true
  has_many :used_institution_tests, foreign_key: 'used_by_test_transaction_id', class_name: 'InstitutionTest', through: :test_transactions

  validates :Code, presence: true, uniqueness: true

  def is_regspec_sample?
    (self.project_ids & [15, 16, 17]).any?
  end

  def is_registered?
    Sample.find_by(Code: self.Code).present? ? true : false
  end

  def sample
    Sample.find_by(Code: self.Code)
  end

  def projects_names
    proj_ids = self.projects.map { |p| p.Id  }
    tests = V1::Common::AVAILABLE_TESTS
    return tests.select{|t| proj_ids.include?(t[:id]) }.map{|t| t[:name]}
  end

  def as_json(options = {})
    super options.merge(methods: :projects_names)
  end

  def shop_order
    rsc = self.package_id
    shop_order = ShopOrder.where("package_ids LIKE ?", "%#{rsc}%").limit(1).first if !rsc.nil?
    shop_order
  end

  def retrieve_institution_tests
    TestTransaction.skip_callback(:create, :after, :change_test_amount)

    self.used_institution_tests.each do |uit|
      trns = self.test_transactions.create!(project_id: uit.project_id, amount_change: 1, contractor_id: Current.api_account.contractor.Id)
      trns.institution_tests.insert_all([{ institution_id: Current.api_account.institution.id, project_id: uit.project_id,
                                           expiry_date: calculate_test_expiry_date(uit), created_at: Time.zone.now, updated_at: Time.zone.now }])
    end

    self.test_transactions.each(&:remove_used_tests)
    self.reserved_tests.destroy_all

    TestTransaction.set_callback(:create, :after, :change_test_amount)
  end

  private

  def calculate_test_expiry_date(old_test)
    old_expiry_date = old_test.expiry_date
    if old_expiry_date < Time.zone.today + 3.months
      Time.zone.today + 3.months + 1.day
    else
      old_expiry_date
    end
  end

end
