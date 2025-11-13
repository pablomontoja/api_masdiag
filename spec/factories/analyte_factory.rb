# == Schema Information
#
# Table name: Analytes
#
#  Id                            :integer          not null, primary key
#  Name                          :text(4294967295) not null
#  ProjectId                     :integer          not null
#  IsCalculatedFromOthers        :boolean          not null
#  CutoffMin                     :decimal(11, 4)
#  CutoffMax                     :decimal(11, 4)
#  Unit                          :text(4294967295)
#  NameInReport                  :text(4294967295)
#  NameInAPI                     :text(4294967295)
#  analysis_method_name_in_batch :string(255)
#  AnalysisMethodPolarity        :text(4294967295)
#  is_required                   :boolean          not null
#  NameInStandLab                :text(255)
#  ExcludedFromStatistic         :boolean          not null
#  material_type                 :integer          not null
#
FactoryBot.define do
  factory :analyte, class: Analyte do
    Name { "Analyte 1" }
    CutoffMin { 1 }
    CutoffMax { 2 }
    IsCalculatedFromOthers { true }
    Unit { "ng/ml" }
    NameInReport { "Analyte 1" }
    NameInAPI { "analyte_1" }
    is_required { true }
    ExcludedFromStatistic { true }
    material_type { :dbs }
  end
end
