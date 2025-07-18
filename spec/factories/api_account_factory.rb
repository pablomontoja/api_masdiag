# == Schema Information
#
# Table name: api_accounts
#
#  id                  :bigint           not null, primary key
#  username            :string(255)
#  password_digest     :string(255)
#  contractor_id       :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  settings_ciphertext :text(65535)
#  language            :string(255)      default("pl"), not null
#
FactoryBot.define do
  factory :api_account, class: ApiAccount do
    username { "username" }
    password { "password" }
  end
end
