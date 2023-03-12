FactoryBot.define do
  factory :reserved_sample_code, class: ReservedSampleCode do
    Code { "JV4XJ" }
    InstitutionId { 1 }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 1 }
  end

  factory :second_reserved_sample_code, class: ReservedSampleCode do
    Code { "NLEZA" }
    InstitutionId { 1 }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 2 }
  end

  factory :rsc_without_institution, class: ReservedSampleCode do
    Code { "JV4XJ" }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 1 }
  end
end
