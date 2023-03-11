FactoryBot.define do
  factory :patient, class: Patient do
    email { Faker::Internet.email }
    email_confirmation { email }
    FirstName { Faker::Name.first_name }
    LastName { Faker::Name.last_name }
    Pesel { 87062615432 }
    Gender { 0 }
    contractor
  end
end