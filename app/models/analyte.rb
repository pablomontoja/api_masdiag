class Analyte < ApplicationRecord
	self.table_name = "Analytes"
	self.primary_key = "Id"

	belongs_to :project, class_name: "Project", foreign_key: "ProjectId"
	has_many :analyte_ranges, class_name: "AnalyteRange", foreign_key: "AnalyteId"

  # def readonly?
  #   true
  # end

end