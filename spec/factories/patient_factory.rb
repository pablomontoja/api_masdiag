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