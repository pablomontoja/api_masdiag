# == Schema Information
#
# Table name: Samples
#
#  Id                            :integer          not null, primary key
#  Code                          :string(50)       not null
#  ProtocolName                  :text(4294967295)
#  IsControlSample               :boolean          default(FALSE), not null
#  IsWrongRegistration           :boolean          default(FALSE), not null
#  IsSentBack                    :boolean          default(FALSE), not null
#  SentBackDate                  :datetime
#  Description                   :text(4294967295)
#  RegistrationDate              :datetime
#  IsValid                       :boolean          default(TRUE), not null
#  PatientId                     :integer
#  UserId                        :integer
#  ProtocolIdOld                 :integer
#  IsAuthWithoutResult           :boolean          default(FALSE), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  payment_status                :integer
#  AcceptanceDate                :datetime
#  access_hash                   :string(255)
#  sample_collection_date        :datetime
#  UnsatisfactoryMaterialQuality :boolean          default(FALSE), not null
#  soaking_degree_id             :integer
#  WasWrongRegistration          :boolean          not null
#  MaterialType                  :integer          not null
#  SampleStatus                  :integer          not null
#  SampleState                   :integer          not null
#  Comment                       :text(4294967295)
#  CancellationDate              :datetime
#  ArchivingDate                 :datetime
#  WrongRegistrationStatus       :integer          not null
#  CancelledById                 :integer
#  UtilizationDate               :datetime
#  institution_custom_cbx        :boolean
#  Lot                           :text(255)
#  Level                         :text(255)
#  selected_tests                :text(65535)
#  clinical_info                 :text(65535)
#
FactoryBot.define do
  factory :sample, class: Sample do
    Code { "JV4XJ" }
    sample_collection_date { Date.today }
    RegistrationDate { 2.days.ago }
    WasWrongRegistration { false }
    SampleState { 1 }
    SampleStatus { 1 }
    WrongRegistrationStatus { 0 }
    MaterialType { 0 }
    patient
    # soaking_degree
  end
end


FactoryBot.define do
  factory :not_registered_sample_in_lab, class: Sample do
    Code { "JV4XJ" }
    sample_collection_date { Date.today }
    RegistrationDate { Date.today }
    AcceptanceDate { 2.days.ago }
    IsWrongRegistration { true }
    WasWrongRegistration { false }
    SampleState { 2 }
    SampleStatus { 2 }
    WrongRegistrationStatus { 1 }
    MaterialType { 0 }
    association :patient, factory: :virtual_patient
    # soaking_degree
  end
end



FactoryBot.define do
  factory :sample_with_pesel, class: Hash do
    sample do
      {
        "code": "JV4XJ",
        "sample_collection_date": "2022-04-10",
        "patient_attributes": {
          "email": "email@domain.com",
          "first_name": "Paweł",
          "last_name": "Świder",
          "pesel": "73080335755"
        }
      }
    end
    skip_create
    initialize_with { attributes }
  end
end


FactoryBot.define do
  factory :sample_without_pesel, class: Hash do
    sample do
      {
        "code": "JV4XJ",
        "sample_collection_date": "2022-04-10",
        "patient_attributes": {
          "email": "email@domain.com",
          "first_name": "Paweł",
          "last_name": "Świder",
          "pesel": "",
          "birth_date": "2010-02-14",
          "gender": "0",
          "id_document": 1,
          "id_number": "AA"
        }
      }
    end
    skip_create
    initialize_with { attributes }
  end
end


FactoryBot.define do
  factory :sample_foreigner, class: Hash do
    sample do
      {
        "code": "JV4XJ",
        "sample_collection_date": "2022-04-10",
        "patient_attributes": {
          "email": nil,
          "first_name": "Paweł",
          "last_name": "Świder",
          "birth_date": "2010-02-14",
          "gender": "0"
        }
      }
    end
    skip_create
    initialize_with { attributes }
  end
end
