FactoryBot.define do
  factory :patient, class: Patient do
    email { Faker::Internet.email }
    email_confirmation { email }
    FirstName { Faker::Name.first_name }
    LastName { Faker::Name.last_name }
    Pesel { 73080335755 }
    Gender { 0 }
    contractor
  end
end


FactoryBot.define do
  factory :virtual_patient, class: Patient do
    email { Faker::Internet.email }
    email_confirmation { email }
    FirstName { "Wirtualny" }
    LastName { "Pacjent" }
    Pesel { nil }
    Gender { 0 }
    BirthDate { Date.parse "2000-01-02 00:00:00" }
    IsVirtual { true }
    contractor
  end
end