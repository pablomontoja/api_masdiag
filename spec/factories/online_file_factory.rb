FactoryBot.define do
  factory :online_file, class: OnlineFile do
    measurement
    file_size { 0 }
    content_type { "Application/pdf" }
    encrypted_file_size { 0 }
    # sample_collection_date { Date.today }
  end
end