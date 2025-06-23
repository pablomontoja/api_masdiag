# == Schema Information
#
# Table name: Contractors
#
#  Id                         :integer          not null, primary key
#  Name                       :text(4294967295)
#  Address                    :text(4294967295)
#  created_at                 :datetime
#  updated_at                 :datetime
#  email                      :string(255)      default(""), not null
#  encrypted_password         :string(255)      default(""), not null
#  reset_password_token       :string(255)
#  reset_password_sent_at     :datetime
#  remember_created_at        :datetime
#  sign_in_count              :integer          default(0), not null
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  first_name                 :string(255)
#  last_name                  :string(255)
#  nip                        :string(255)
#  approved                   :boolean          default(FALSE), not null
#  are_notifications_enabled  :boolean          default(FALSE), not null
#  type_of_contractor         :integer          default(0), not null
#  institution_id             :integer
#  agent_id                   :integer
#  phone                      :string(255)
#  invalid_first_or_last_name :boolean          not null
#  patient_is_orderer         :boolean          not null
#  is_super_contractor        :boolean          default(FALSE)
#  can_add_samples            :boolean          default(TRUE)
#  confirmed_at               :datetime
#  confirmation_sent_at       :datetime
#  confirmation_token         :string(255)
#  unconfirmed_email          :string(255)
#  creator_id                 :integer
#
FactoryBot.define do
  factory :contractor, class: Contractor do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    invalid_first_or_last_name { false }
    patient_is_orderer { false }
    institution
  end
end


# "Id":"8"
# "Name":null
# "Address":null
# "created_at":"2016-11-04 11:35:15"
# "updated_at":"2022-01-18 09:36:03"
# "email":"pawelswider@gmail.com"
# "encrypted_password":"$2a$12$eQ\/pNVunljUD92\/sq8\/aMuEWdxPDU4I5idnp.0cLBBUyWcMW.T5zK"
# "reset_password_token":"a3dcb72bb999c007c3df9be3afbf8c89c634e77f99904d7c435b827086c65a8f"
# "reset_password_sent_at":"2022-01-18 09:36:03"
# "remember_created_at":null
# "sign_in_count":"235"
# "current_sign_in_at":"2021-09-02 11:44:56"
# "last_sign_in_at":"2021-09-02 11:13:14"
# "current_sign_in_ip":"178.73.3.98"
# "last_sign_in_ip":"178.73.3.98"
# "first_name":"Paweł"
# "last_name":"Świder"
# "nip":null
# "approved":"1"
# "are_notifications_enabled":"1"
# "type_of_contractor":"0"
# "institution_id":"1"
# "agent_id":null
# "phone":null
# "invalid_first_or_last_name":"0"
# "patient_is_orderer":"0"
# "is_super_contractor":"1"
# "can_add_samples":"1"
# "confirmed_at":"2021-04-24 20:01:34"
# "confirmation_sent_at":null
# "confirmation_token":null
# "unconfirmed_email":null
# "creator_id":null
