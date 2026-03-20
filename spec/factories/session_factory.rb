FactoryBot.define do
  factory :session, class: Session do
    contractor
    token { SecureRandom.urlsafe_base64(32) }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec" }
    last_active_at { Time.current }
  end
end
