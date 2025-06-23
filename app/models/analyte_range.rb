# == Schema Information
#
# Table name: AnalyteRanges
#
#  Id              :integer          not null, primary key
#  Name            :text(4294967295)
#  AgeFrom         :integer          not null
#  AgeTo           :integer          not null
#  Gender          :integer
#  Min             :decimal(18, 2)   not null
#  Max             :decimal(18, 2)   not null
#  AnalyteId       :integer
#  AgeFromMonth    :integer          not null
#  AgeToMonth      :integer          not null
#  AgeFromInMonths :integer          not null
#  AgeToInMonths   :integer          not null
#  Multiplier      :decimal(18, 2)   not null
#  AcceptableMin   :decimal(18, 2)
#  AcceptableMax   :decimal(18, 2)
#  MaterialType    :integer          not null
#
class AnalyteRange < ApplicationRecord
	self.table_name = "AnalyteRanges"
	self.primary_key = "Id"

	belongs_to :analyte, class_name: "Analyte", foreign_key: "AnalyteId"
	has_one :project, through: :analyte

  # def readonly?
  #   true
  # end  
end
