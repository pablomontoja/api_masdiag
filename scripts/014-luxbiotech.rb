###################
# staging
###################
# inst = Institution.create!(name: "Luxbiotech", nip: "Registration Number 2022 2412 839", address: "16 rue des Prés, L8147 Bridel Luxembourg", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "16 rue des Prés, L8147 Bridel, Luxembourg", street: "16 rue des Prés, L8147 Bridel", postal_code: "L8147 Bridel", city: "Luxembourg", company_for_shipments: nil, shipment_street: "16 rue des Prés, L8147 Bridel", shipment_postal_code: "L8147 Bridel", shipment_city: "Luxembourg", region_of_activity: 0 )

# inst = Institution.create!("name": "EU - Lalen Dogan", "address": "Suite 2080, 112 Snell Grove, Oak Park VIC 3046 Australia", "nip": "VAT no 77 656 625 893", "created_at": "Fri, 01 Dec 2023 16:17:47 UTC +00:00", "updated_at": "Fri, 01 Dec 2023 16:17:47 UTC +00:00", "allow_patient_email": false, "has_approve_messages_for_patients": false, "has_payment_status_in_samples": false, "logo_file": nil, "krs": nil, "regon": nil, "discount_id": nil, "has_disabled_invoices": true, "approve_contractor_after_registration": false, "email": nil, "created_by_agent_id": nil, "region_of_activity": 1, "wants_summary_of_performed_samples": false, "footer_phone_and_email": nil, "patient_email_template_body": nil, "contractor_email_template_body": nil, "inivitation_jpg_image": nil, "email_attachment_pdf": nil, "custom_cbx_text_in_sample_form": nil, "smtp_settings_name": nil, "smtp_email": nil, "test_alert_treshold": nil, "shipping_address": "Suite 2080, 112 Snell Grove, Oak Park VIC 3046 Australia", "terms_accepted": nil, "terms_accepted_at": nil, "auto_test_charge": false, "electronic_invoice_acceptance": nil, "electronic_invoice_accepted_at": nil, "terms_version": nil, "street": "Suite 2080, 112 Snell Grove, Oak Park", "postal_code": "VIC 3046", "city": "Melbourne", "company_for_shipments": nil, "shipment_street": "Suite 2080, 112 Snell Grove, Oak Park", "shipment_postal_code": "VIC 3046", "shipment_city": "Melbourne", "email_for_results": nil)

# contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "luxbiotech@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

# ApiAccount.create!(username: "luxbiotech", password: "nujZQz7XF32ftB6W", password_confirmation: "nujZQz7XF32ftB6W", contractor_id: contractor.Id, language: "en")
# staging: nujZQz7XF32ftB6W
# production: Kaw27HREyfsP5WAv



require 'faker'

inst = Institution.find_by(name: "EU - Lalen Dogan")
Current.api_account = ApiAccount.find_by(username: "luxbiotech")
user = User.find_by(email: "pawel.swider@masdiag.pl")


po = ProductionOrder.new(lot: "005.Luxbiotech", packages_expiry_date: Date.parse("2025-04-01"), packages_count: 10, product_id: 1, stock_room_id: 1)
ProductionOrdersJob.perform_now(po.attributes, user)

omegaquant_codes = ["EUAA00011", "EUAA00012", "EUAA00013", "EUAA00014", "EUAA00015", "EUAA00016", "EUAA00017", "EUAA00018", "EUAA00019", "EUAA00020"]

ProductionOrder.find_by(lot: "005.Luxbiotech").reserved_sample_codes.each do |rsc|
  rsc.reserved_tests.destroy_all
  rsc.reserved_tests.create!(project_id: 21)
  c = omegaquant_codes.sample
  rsc.update(Code: c, IsRetailSale: true, InstitutionId: inst.id)
  omegaquant_codes.delete(c)
end


all_codes = ProductionOrder.find_by(lot: "005.Luxbiotech").reserved_sample_codes.pluck(:Code)
codes = all_codes.sample(3)
all_codes = all_codes - codes

codes.each do |code|
  params = {code: code, sample_collection_date: "2024-05-08", patient_attributes: {
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

params = {code: accepted_code, sample_collection_date: "2024-05-08", patient_attributes: {
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

# cancelled_code = all_codes.sample()
# all_codes.delete(cancelled_code)

# params = {code: cancelled_code, sample_collection_date: "2024-05-08", patient_attributes: {
#             email: Faker::Internet.email,
#             first_name: Faker::Name.first_name,
#             last_name: Faker::Name.last_name,
#             birth_date: Faker::Date.birthday(min_age: 1, max_age: 150),
#             gender: [0, 1].sample
#           }
#           }
# sample = V1::SampleCreator.call(params, ReservedSampleCode.find_by(Code: cancelled_code))
# sample.save!

# smp = Sample.find_by(Code: cancelled_code)
# smp.measurements.destroy_all
# smp.update(Comment: "materiał niezakwalifikowany do badania", SampleStatus: 4, CancelledById: 1,AcceptanceDate: DateTime.now, CancellationDate: DateTime.now, soaking_degree_id: [4,5].sample)

# expired_code = all_codes.sample()
# all_codes.delete(expired_code)

# rsc = ReservedSampleCode.find_by(Code: expired_code)
# rsc.update(expiry_date: 1.day.ago)
# rsc.package.update(expiry_date: 1.day.ago)

pp "free_codes - #{all_codes}"
pp "accepted but without results yet - #{accepted_code}"
pp "accepted with results: - #{codes}"



meases = Measurement.includes(sample: {patient: :contractor}).where(sample: {Patients: {ContractorId: Current.api_account.contractor.Id}}).where(Status: 5, ProjectId: [2,3,10,12,14,21]).order(I
d: :desc)

ActiveRecord::Base.transaction do
  meases.each do |meas|
    meas.result&.destroy
    result = Result.create(MeasurementId: meas.Id, ImportDate: Time.now - 14.days, IsValid: true, ImportUserId: user.Id)

    meas.project.analytes.where(is_required: true).each do |analyte|
      fake_value = Faker::Number.within(range: 0.0..100.0)
      fake_value = Faker::Number.within(range: analyte.CutoffMin..analyte.CutoffMax) if !analyte.CutoffMin.nil? && !analyte.CutoffMax.nil?
      result.analyte_results.create(AnalyteId: analyte.Id, Value: fake_value, Unit: analyte.Unit, MeasuredValue: fake_value)
    end
  end
end





# free_codes - ["EUAA00014", "EUAA00012", "EUAA00018", "EUAA00017", "EUAA00020", "EUAA00011"]
# accepted but without results yet - "EUAA00016"
# accepted with results: - ["EUAA00013", "EUAA00015", "EUAA00019"]

