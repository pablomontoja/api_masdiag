# == Schema Information
#
# Table name: sessions
#
#  id             :bigint           not null, primary key
#  contractor_id  :integer          not null
#  ip_address     :string(255)
#  user_agent     :string(255)
#  token          :string(255)      not null
#  last_active_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
FactoryBot.define do
  factory :session, class: Session do
    contractor
    token { SecureRandom.urlsafe_base64(32) }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec" }
    last_active_at { Time.current }
  end
end
