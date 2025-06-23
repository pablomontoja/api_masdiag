# == Schema Information
#
# Table name: Analytes
#
#  Id                            :integer          not null, primary key
#  Name                          :text(4294967295) not null
#  ProjectId                     :integer          not null
#  IsCalculatedFromOthers        :boolean          not null
#  CutoffMin                     :decimal(9, 2)
#  CutoffMax                     :decimal(9, 2)
#  Unit                          :text(4294967295)
#  NameInReport                  :text(4294967295)
#  NameInAPI                     :text(4294967295)
#  analysis_method_name_in_batch :string(255)
#  AnalysisMethodPolarity        :text(4294967295)
#  is_required                   :boolean          not null
#  NameInStandLab                :text(255)
#  ExcludedFromStatistic         :boolean          not null
#
class Analyte < ApplicationRecord
	self.table_name = "Analytes"
	self.primary_key = "Id"

	belongs_to :project, class_name: "Project", foreign_key: "ProjectId"
	has_many :analyte_ranges, class_name: "AnalyteRange", foreign_key: "AnalyteId"

  # def readonly?
  #   true
  # end

end
