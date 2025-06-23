# == Schema Information
#
# Table name: Patients
#
#  Id                    :integer          not null, primary key
#  RegistrationDate      :datetime         not null
#  FirstName             :text(4294967295) not null
#  LastName              :text(4294967295) not null
#  Pesel                 :text(4294967295)
#  BirthDate             :datetime         not null
#  Gender                :integer          not null
#  ContractorId          :integer          not null
#  CreatedById           :integer
#  CreatedAt             :datetime
#  ModifiedById          :integer
#  ModifiedAt            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  email                 :string(255)
#  phone                 :string(255)
#  is_foreigner          :boolean          default(FALSE), not null
#  approve1              :boolean          default(FALSE)
#  approve2              :boolean          default(FALSE)
#  approve3              :boolean          default(FALSE)
#  language              :string(255)      default("pl"), not null
#  approve_personal_data :boolean          default(FALSE)
#  IsVirtual             :boolean          not null
#  send_results_on_mail  :boolean          default(FALSE), not null
#  body_weight           :string(255)
#  body_height           :string(255)
#  id_document           :integer
#  id_number             :string(255)
#
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
