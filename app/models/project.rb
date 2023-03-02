class Project < ApplicationRecord
	self.table_name = "Projects"
	self.primary_key = "Id"

	scope :enabled_online, -> { where(is_blocked_online: 'false') }
	
	has_many :measurements, class_name: "Measurement", foreign_key: "ProjectId"
	has_many :analytes, class_name: "Analyte", foreign_key: "ProjectId"
	has_many :reserved_tests
	has_many :reserved_sample_codes, through: :reserved_tests

  def readonly?
    Rails.env.test? ? false : true
  end

end
