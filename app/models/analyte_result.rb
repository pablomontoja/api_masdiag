class AnalyteResult < ApplicationRecord
	self.table_name = "AnalyteResults"
	self.primary_key = ["ResultId", "AnalyteId"]

	belongs_to :result, class_name: "Result", foreign_key: "ResultId"
	belongs_to :analyte, class_name: "Analyte", foreign_key: "AnalyteId"

  # def readonly?
  #   true
  # end  
end