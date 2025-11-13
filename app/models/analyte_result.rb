# == Schema Information
#
# Table name: AnalyteResults
#
#  ResultId             :integer          not null, primary key
#  AnalyteId            :integer          not null, primary key
#  Value                :decimal(20, 4)   not null
#  Unit                 :text(4294967295)
#  Result_MeasurementId :integer
#  MeasuredValue        :decimal(18, 5)   not null
#
class AnalyteResult < ApplicationRecord
	self.table_name = "AnalyteResults"
	self.primary_key = ["ResultId", "AnalyteId"]

	belongs_to :result, class_name: "Result", foreign_key: "ResultId"
	belongs_to :analyte, class_name: "Analyte", foreign_key: "AnalyteId"

  # def readonly?
  #   true
  # end  
end
