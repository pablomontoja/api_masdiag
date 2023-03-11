FactoryBot.define do
  factory :api_account, class: ApiAccount do
    username { "username" }
    password { "password" }
    contractor_id { 1 }
  end
end
