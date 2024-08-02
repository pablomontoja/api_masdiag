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