# == Schema Information
#
# Table name: AnalyteRanges
#
#  Id              :integer          not null, primary key
#  Name            :text(4294967295)
#  AgeFrom         :integer          not null
#  AgeTo           :integer          not null
#  Gender          :integer
#  Min             :decimal(20, 4)   not null
#  Max             :decimal(20, 4)   not null
#  AnalyteId       :integer
#  AgeFromMonth    :integer          not null
#  AgeToMonth      :integer          not null
#  AgeFromInMonths :integer          not null
#  AgeToInMonths   :integer          not null
#  Multiplier      :decimal(18, 2)   not null
#  AcceptableMin   :decimal(20, 4)
#  AcceptableMax   :decimal(20, 4)
#
class AnalyteRange < ApplicationRecord
	self.table_name = "AnalyteRanges"
	self.primary_key = "Id"

	belongs_to :analyte, class_name: "Analyte", foreign_key: "AnalyteId"
	has_one :project, through: :analyte

  validates :Gender, uniqueness: { scope: [:AnalyteId, :AgeFromInMonths, :AgeToInMonths] }  
end
