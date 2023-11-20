class AnalyteRange < ApplicationRecord
	self.table_name = "AnalyteRanges"
	self.primary_key = "Id"

	belongs_to :analyte, class_name: "Analyte", foreign_key: "AnalyteId"
	has_one :project, through: :analyte

  # def readonly?
  #   true
  # end  
end