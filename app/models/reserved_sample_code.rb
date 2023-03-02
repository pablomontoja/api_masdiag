class ReservedSampleCode < ApplicationRecord
  self.table_name = "ReservedSampleCodes"
  self.primary_key = "Id"

  belongs_to :package
  belongs_to :institution, class_name: "Institution", foreign_key: "InstitutionId", optional: true
  # belongs_to :project, class_name: "Project", foreign_key: "ProjectId", optional: true
  has_many :reserved_tests
  has_many :projects, through: :reserved_tests
  has_many :test_transactions
  belongs_to :reserved_by, foreign_key: :reserved_by_contractor_id, class_name: "Contractor", optional: true

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
    return self.projects.map { |p| p.Name  }
  end

  def as_json(options = {})
    super options.merge(methods: :projects_names)
  end

  def shop_order
    rsc = self.package_id
    shop_order = ShopOrder.where("package_ids LIKE ?", "%#{rsc}%").limit(1).first if !rsc.nil?
    shop_order
  end

end
