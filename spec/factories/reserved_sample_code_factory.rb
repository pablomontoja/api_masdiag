# == Schema Information
#
# Table name: ReservedSampleCodes
#
#  Id                        :integer          not null, primary key
#  Code                      :text(4294967295)
#  CreatedAt                 :datetime         not null
#  CreatedById               :integer
#  InstitutionId             :integer
#  IsRetailSale              :boolean          not null
#  SerialNumber              :integer
#  ExtendedSerialNumber      :text(4294967295)
#  OwnerEmail                :string(255)
#  package_type              :integer
#  expiry_date               :datetime
#  reserved_by_contractor_id :integer
#  lot                       :string(255)
#  ref                       :string(255)
#  package_id                :bigint
#  parent_id                 :integer
#  comment                   :text(65535)
#  assignment_date           :datetime
#  MaterialType              :integer          default("dbs"), not null
#  material_handler          :integer          default("dbs_t4"), not null
#
FactoryBot.define do
  factory :reserved_sample_code, class: ReservedSampleCode do
    Code { "JV4XJ" }
    InstitutionId { 1 }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 1 }
    IsRetailSale { true }
  end

  factory :second_reserved_sample_code, class: ReservedSampleCode do
    Code { "NLEZA" }
    InstitutionId { 1 }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 2 }
    IsRetailSale { true }
  end

  factory :rsc_without_institution, class: ReservedSampleCode do
    Code { "JV4XJ" }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 1 }
  end

  factory :rsc_code_with_dash, class: ReservedSampleCode do
    Code { "E1A-71498" }
    expiry_date { 1.year.since }
    CreatedAt { Time.now }
    package_id { 1 }
  end  
end
