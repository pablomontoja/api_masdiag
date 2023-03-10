Institution.create!(name: "Masdiag Sp. z o.o.", nip: "5222996468", address: "Żeromskiego 33, 01-882 Warszawa", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "Żeromskiego 33, 01-882 Warszawa", street: "Żeromskiego 33", postal_code: "01-882", city: "Warszawa", company_for_shipments: nil, shipment_street: "Żeromskiego 33", shipment_postal_code: "01-882", shipment_city: "Warszawa", region_of_activity: 0 )

inst = Institution.create!(name: "Epixpert sp. z o.o.", nip: "5252821696", address: "Kryniczna 7, 03-934 Warszawa", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "Kryniczna 7, 03-934 Warszawa", street: "Kryniczna 7", postal_code: "03-934", city: "Warszawa", company_for_shipments: nil, shipment_street: "Kryniczna 7", shipment_postal_code: "03-934", shipment_city: "Warszawa", region_of_activity: 0 )


contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "email@email.com", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)


ApiAccount.create!(username: "epixpert", password: "8LhEkEdkPj4EQQ34", password_confirmation: "8LhEkEdkPj4EQQ34", contractor_id: contractor.Id)


user = User.create!(FirstName: "Paweł", LastName: "Świder", email: "pawel.swider@masdiag.pl", Login: "pswider", Password: "pass", Salt: "salt", IsActive: true, Role: 0, encrypted_password: "$", sign_in_count: 0, HasSmartCard: false)


po = ProductionOrder.new(lot: "001.Epixpert", packages_expiry_date: Date.parse("2023-04-01"), packages_count: 10, product_id: 1, stock_room_id: 1, material_type: 0)
ProductionOrdersJob.perform_now(po.attributes, user)


ProductionOrder.find_by(lot: "001.Epixpert").reserved_sample_codes.each do |rsc|
  rsc.reserved_tests.destroy_all
  project_id = [2,3,10,12,14].sample
  rsc.reserved_tests.create!(project_id: project_id)
  rsc.reserved_tests.create!(project_id: ([2,3,10,12,14]-[project_id]).sample) if [true,false].sample
  rsc.update(IsRetailSale: true, InstitutionId: inst.id)
end


codes = ["74VXV", "TYA4S", "VPCZK"]
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




# ZJKXP jest przyjety do Labu, ale nie ma wyników
# BHCLC anulowana

smp = Sample.find_by(Code: "BHCLC")
smp.measurements.destroy_all
smp.update(Comment: "materiał niezakwalifikowany do badania", SampleStatus: 4, CancelledById: 1, CancellationDate: DateTime.now, soaking_degree_id: [4,5].sample)
