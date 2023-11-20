###################
# staging
###################
inst = Institution.create!(name: "FoodForTheBrain", nip: "GB unknown", address: "34-35 Nabarro, Chartered Accountants, 4th Floor, 34-35 Eastcastle Street, London", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "34-35 Nabarro, Chartered Accountants, 4th Floor, 34-35 Eastcastle Street, London", street: "34-35 Nabarro, Chartered Accountants, 4th Floor, 34-35 Eastcastle Street", postal_code: "W1W 8DW", city: "London", company_for_shipments: nil, shipment_street: "34-35 Nabarro, Chartered Accountants, 4th Floor, 34-35 Eastcastle Street", shipment_postal_code: "W1W 8DW", shipment_city: "London", region_of_activity: 0 )

contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "foodforthebrain@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

ApiAccount.create!(username: "foodforthebrain", password: "KRZsuT8MJ2xDUdNv", password_confirmation: "KRZsuT8MJ2xDUdNv", contractor_id: contractor.Id, language: "en")




require 'faker'

inst = Institution.find_by(name: "FoodForTheBrain")
Current.api_account = ApiAccount.find_by(username: "foodforthebrain")
user = User.find_by(email: "pawel.swider@masdiag.pl")


po = ProductionOrder.new(lot: "004.FoodForTheBrain", packages_expiry_date: Date.parse("2025-04-01"), packages_count: 10, product_id: 1, stock_room_id: 1)
ProductionOrdersJob.perform_now(po.attributes, user)

omegaquant_codes = ["EUAA00001", "EUAA00002", "EUAA00003", "EUAA00004", "EUAA00005", "EUAA00006", "EUAA00007", "EUAA00008", "EUAA00009", "EUAA00010"]

ProductionOrder.find_by(lot: "004.FoodForTheBrain").reserved_sample_codes.each do |rsc|
  rsc.reserved_tests.destroy_all
  project_id = [2, 12].sample
  rsc.reserved_tests.create!(project_id: project_id)
  rsc.reserved_tests.create!(project_id: ([2, 12]-[project_id]).sample) if [true,true,false].sample
  c = omegaquant_codes.sample
  rsc.update(Code: c, IsRetailSale: true, InstitutionId: inst.id)
  omegaquant_codes.delete(c)
end


all_codes = ProductionOrder.find_by(lot: "004.FoodForTheBrain").reserved_sample_codes.pluck(:Code)
codes = all_codes.sample(3)
all_codes = all_codes - codes

codes.each do |code|
  params = {code: code, sample_collection_date: "2023-11-08", patient_attributes: {
              email: Faker::Internet.email,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              birth_date: Faker::Date.birthday(min_age: 1, max_age: 150),
              gender: [0, 1].sample
            }
            }
  sample = V1::SampleCreator.call(params, ReservedSampleCode.find_by(Code: code))
  sample.save!
end

file = File.open("scripts/blank.pdf")
Measurement.includes(:sample).where(sample: {Code: codes}).each do |meas|
  meas.online_file&.destroy
  of = OnlineFile.new(measurement_id: meas.Id, file_size: file.size, encrypted_file_size: file.size, filename: "#{meas.sample.Code}_#{meas.ProjectId}", content_type: "application/pdf")
  of.file_contents = file.read
  file.rewind
  of.encrypted_file_contents = file.read
  file.rewind
  of.save
  meas.update(Status: 5, MeasureDate: DateTime.now, AuthorizedAt: DateTime.now, CuttedAt: DateTime.now, InstrumentId: 1)
  meas.sample.update(AcceptanceDate: DateTime.now-2.days, soaking_degree_id: 1, SampleStatus: 2, SampleState: 2)
end

accepted_code = all_codes.sample()
all_codes.delete(accepted_code)

params = {code: accepted_code, sample_collection_date: "2023-11-10", patient_attributes: {
            email: Faker::Internet.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            birth_date: Faker::Date.birthday(min_age: 1, max_age: 150),
            gender: [0, 1].sample
          }
          }
sample = V1::SampleCreator.call(params, ReservedSampleCode.find_by(Code: accepted_code))
sample.save!

Measurement.includes(:sample).where(sample: {Code: accepted_code}).each do |meas|
  meas.update(Status: 1, MeasureDate: DateTime.now, AuthorizedAt: DateTime.now, CuttedAt: DateTime.now, InstrumentId: 1)
  meas.sample.update(AcceptanceDate: DateTime.now-2.days, soaking_degree_id: [1,2,3].sample, SampleStatus: 2, SampleState: 2)
end

cancelled_code = all_codes.sample()
all_codes.delete(cancelled_code)

params = {code: cancelled_code, sample_collection_date: "2023-11-09", patient_attributes: {
            email: Faker::Internet.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            birth_date: Faker::Date.birthday(min_age: 1, max_age: 150),
            gender: [0, 1].sample
          }
          }
sample = V1::SampleCreator.call(params, ReservedSampleCode.find_by(Code: cancelled_code))
sample.save!

smp = Sample.find_by(Code: cancelled_code)
smp.measurements.destroy_all
smp.update(Comment: "materiał niezakwalifikowany do badania", SampleStatus: 4, CancelledById: 1,AcceptanceDate: DateTime.now, CancellationDate: DateTime.now, soaking_degree_id: [4,5].sample)

expired_code = all_codes.sample()
all_codes.delete(expired_code)

rsc = ReservedSampleCode.find_by(Code: expired_code)
rsc.update(expiry_date: 1.day.ago)
rsc.package.update(expiry_date: 1.day.ago)

pp "free_codes - #{all_codes}"
pp "accepted but without results yet - #{accepted_code}"
pp "accepted with resuls: - #{codes}"
pp "cancelled - #{cancelled_code}"
pp "expired - #{expired_code}"


# "free_codes - [\"EUAA00009\", \"EUAA00007\", \"EUAA00004\", \"EUAA00003\"]"
# "accepted but without results yet - EUAA00010"
# "accepted with resuls: - [\"EUAA00005\", \"EUAA00001\", \"EUAA00006\"]"
# "cancelled - EUAA00008"
# "expired - EUAA00002"
