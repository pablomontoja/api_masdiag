class Result < ApplicationRecord
	self.table_name = "Results"
	self.primary_key = "MeasurementId"
	belongs_to :measurement, class_name: "Measurement", foreign_key: "MeasurementId"
	has_many :analyte_results, class_name: "AnalyteResult", foreign_key: "ResultId", dependent: :destroy

  # def readonly?
  #   true
  # end
	
end
