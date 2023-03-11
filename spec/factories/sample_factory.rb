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


# "sample"=>
# {"Code"=>"JV4XJ", "sample_collection_date"=>"2022-04-10", "patient_attributes"=>{"email"=>"pablomontoja2@gmail.com", "email_confirmation"=>"pablomontoja2@gmail.com", "FirstName"=>"Paweł", "LastName"=>"Świder", "Pesel"=>"83070212412", "BirthDate"=>"", "Gender"=>"1", "ContractorId"=>"336"}