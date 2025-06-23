# == Schema Information
#
# Table name: Measurements
#
#  Id                :integer          not null, primary key
#  SampleId          :integer          not null
#  ProjectId         :integer          not null
#  ResultId          :integer
#  IsRepeat          :boolean          default(FALSE), not null
#  Status            :integer          not null
#  MeasureDate       :datetime
#  IsValid           :boolean          default(FALSE), not null
#  LabCode           :text(4294967295)
#  CreatedById       :integer
#  CreatedAt         :datetime
#  ModifiedById      :integer
#  ModifiedAt        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  AuthorizedById    :integer
#  AuthorizedAt      :datetime
#  CuttedAt          :datetime
#  selected_analytes :text(65535)
#  InstrumentId      :integer
#  MaterialType      :integer          default(0), not null
#
FactoryBot.define do
  factory :measurement, class: Measurement do
    sample
    project
    Status { 7 }
    # sample_collection_date { Date.today }
  end
end

# "Id":"1105853"
# "SampleId":"929431"
# "ProjectId":"3"
# "ResultId":null
# "IsRepeat":"0"
# "Status":"7"
# "MeasureDate":null
# "IsValid":"1"
# "LabCode":null
# "CreatedById":null
# "CreatedAt":"2022-07-15 12:56:47"
# "ModifiedById":null
# "ModifiedAt":"2022-07-15 12:56:47"
# "created_at":"2022-07-15 12:56:47"
# "updated_at":"2022-07-15 12:56:47"
# "AuthorizedById":null
# "AuthorizedAt":null
# "CuttedAt":null
# "selected_analytes":null
# "InstrumentId":null
# "MaterialType":"0"
