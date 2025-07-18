# == Schema Information
#
# Table name: Results
#
#  MeasurementId :integer          not null, primary key
#  ImportDate    :datetime         not null
#  Description   :text(4294967295)
#  PlateCode     :text(4294967295)
#  IsValid       :boolean          not null
#  ImportUserId  :integer          not null
#
FactoryBot.define do
  factory :result, class: Result do
    ImportDate { Time.now }
    Description { "Pudełko Diagnostyki Precyzyjnej" }
    PlateCode { "WD0001" }
    IsValid { true }
    ImportUserId { User.find_or_create_by!(FirstName: "Paweł", LastName: "Świder", email: "pawel.swider@masdiag.pl", Login: "pswider", Password: "pass", Salt: "salt", IsActive: true, Role: 0, encrypted_password: "$", sign_in_count: 0, HasSmartCard: false).Id }
  end
end
