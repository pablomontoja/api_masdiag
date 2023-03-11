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