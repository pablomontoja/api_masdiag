###################
# staging
###################
ActiveRecord::Base.transaction do
	inst = Institution.create!(name: "Goldcup (Ahum)", address: "-", nip: "---??---", created_at: "2025-02-18 10:21:24", updated_at: "2025-02-18 10:21:24", allow_patient_email: false, has_approve_messages_for_patients: false, has_payment_status_in_samples: false, logo_file: nil, krs: nil, regon: nil, discount_id: nil, has_disabled_invoices: true, approve_contractor_after_registration: false, email: nil, created_by_agent_id: nil, region_of_activity: 0, wants_summary_of_performed_samples: false, footer_phone_and_email: nil, patient_email_template_body: nil, contractor_email_template_body: nil, inivitation_jpg_image: nil, email_attachment_pdf: nil, custom_cbx_text_in_sample_form: nil, smtp_settings_name: nil, smtp_email: nil, test_alert_treshold: nil, shipping_address: "-", terms_accepted: nil, terms_accepted_at: nil, auto_test_charge: false, electronic_invoice_acceptance: nil, electronic_invoice_accepted_at: nil, terms_version: nil, street: "-", postal_code: "-", city: "-", company_for_shipments: nil, shipment_street: "-", shipment_postal_code: "-", shipment_city: "-", kind: "ForeignInstitution", email_for_results: nil)

	contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "goldcup.ahum@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

	ApiAccount.create!(username: "goldcup.ahum", password: "cDYtVLmjG3xeEX4p", password_confirmation: "cDYtVLmjG3xeEX4p", contractor_id: contractor.Id, language: "en")


	require 'faker'

	inst = Institution.find_by(name: "Goldcup (Ahum)")
	Current.api_account = ApiAccount.find_by(username: "goldcup.ahum")
	user = User.find_by(email: "pawel.swider@masdiag.pl")


	po = ProductionOrder.new(lot: "006.Goldcup (Ahum)", packages_expiry_date: Date.parse("2025-04-01"), packages_count: 10, product_id: 1, stock_room_id: 1)
	ProductionOrdersJob.perform_now(po.attributes, user)

  omegaquant_codes = %w[SEGU386L SEJP83BU SECG2I6D SEIGWXJU SELZAHE6 SEC9I5KB SE83ECJJ SEFN234B SEMIDKL1 SEWBLDJB]

	ProductionOrder.find_by(lot: "006.Goldcup (Ahum)").reserved_sample_codes.each do |rsc|
	  rsc.reserved_tests.destroy_all
	  project_id = [27].sample
	  rsc.reserved_tests.create!(project_id: project_id)
	  c = omegaquant_codes.sample
	  rsc.update(Code: c, IsRetailSale: true, InstitutionId: inst.id)
	  omegaquant_codes.delete(c)
	end


	all_codes = ProductionOrder.find_by(lot: "006.Goldcup (Ahum)").reserved_sample_codes.pluck(:Code)
	codes = all_codes.sample(3)
	all_codes = all_codes - codes

	codes.each do |code|
	  params = {code: code, sample_collection_date: "2025-01-08", patient_attributes: {
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
	  meas.update(Status: 5, MeasureDate: DateTime.now, AuthorizedAt: DateTime.now, CuttedAt: DateTime.now, InstrumentId: 1)
	  meas.sample.update(AcceptanceDate: DateTime.now-2.days, soaking_degree_id: 1, SampleStatus: 2, SampleState: 2)
	end

	accepted_code = all_codes.sample()
	all_codes.delete(accepted_code)

	params = {code: accepted_code, sample_collection_date: "2025-01-10", patient_attributes: {
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

	params = {code: cancelled_code, sample_collection_date: "2025-01-09", patient_attributes: {
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


pp "free_codes - #{all_codes.join(", ")}"
pp "accepted but without results yet - #{accepted_code}"
pp "accepted with results: - #{codes.join(", ")}"
pp "cancelled - #{cancelled_code}"
pp "expired - #{expired_code}"
end

# STAGING
# free_codes - E1A00009, E1A00005, E1A000002, E1A00007
# accepted in lab but without results yet - E1A00008
# accepted in lab with results: - E1A00006, E1A00004, E1A00003
# cancelled - E1A000001
# expired - E1A00010
