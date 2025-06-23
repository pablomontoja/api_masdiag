# == Schema Information
#
# Table name: Results
#
#  MeasurementId :integer          not null, primary key
#  ImportDate    :datetime         not null
#  Description   :text(4294967295)
#  PlateCode     :text(4294967295)
#  IsValid       :boolean          not null
#  ImportUserId  :integer          not null
#
class Result < ApplicationRecord
	self.table_name = "Results"
	self.primary_key = "MeasurementId"
	belongs_to :measurement, class_name: "Measurement", foreign_key: "MeasurementId"
	has_many :analyte_results, class_name: "AnalyteResult", foreign_key: "ResultId", dependent: :destroy

  # def readonly?
  #   true
  # end
	
end
