FactoryBot.define do
  factory :hl7_import do
    s3_key            { "results/#{SecureRandom.hex(8)}.hl7" }
    s3_bucket         { "hl7-results" }
    s3_etag           { SecureRandom.hex(16) }
    file_size         { 1024 }
    hl7_test_code     { "UCR,usEssEl,UsMetox" }
    kit_code_extracted { "A6Y1IF" }
    status            { :pending }
    retry_count       { 0 }

    trait :awaiting_registration do
      status      { :awaiting_registration }
      measurement { nil }
    end

    trait :failed do
      status        { :failed }
      error_message { "Parse failed" }
    end

    trait :completed do
      status       { :completed }
      processed_at { Time.current }
    end

    trait :with_measurement do
      association :measurement
    end
  end
end
