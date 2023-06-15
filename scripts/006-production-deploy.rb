# ###### RAILS
# rails db:migrate
#
# UPDATE `Projects` SET `eng_name` = 'NBS' WHERE `Projects`.`Id` = 1;
# UPDATE `Projects` SET `eng_name` = 'Vitamin D metabolites' WHERE `Projects`.`Id` = 2;
# UPDATE `Projects` SET `eng_name` = 'Aminoacids' WHERE `Projects`.`Id` = 3;
# UPDATE `Projects` SET `eng_name` = 'AED' WHERE `Projects`.`Id` = 5;
# UPDATE `Projects` SET `eng_name` = 'CBD' WHERE `Projects`.`Id` = 6;
# UPDATE `Projects` SET `eng_name` = 'TOXO' WHERE `Projects`.`Id` = 7;
# UPDATE `Projects` SET `eng_name` = 'EDX' WHERE `Projects`.`Id` = 8;
# UPDATE `Projects` SET `eng_name` = 'anty-SARS-CoV-2' WHERE `Projects`.`Id` = 9;
# UPDATE `Projects` SET `eng_name` = 'Vitamin A, E and Coenzyme Q10' WHERE `Projects`.`Id` = 10;
# UPDATE `Projects` SET `eng_name` = 'THC' WHERE `Projects`.`Id` = 11;
# UPDATE `Projects` SET `eng_name` = 'Homocysteine' WHERE `Projects`.`Id` = 12;
# UPDATE `Projects` SET `eng_name` = 'Borreliosis Screening' WHERE `Projects`.`Id` = 13;
# UPDATE `Projects` SET `eng_name` = 'TSH' WHERE `Projects`.`Id` = 14;
# UPDATE `Projects` SET `eng_name` = 'Organic acid profile' WHERE `Projects`.`Id` = 15;
# UPDATE `Projects` SET `eng_name` = 'Purines and Pyrimidines' WHERE `Projects`.`Id` = 16;
# UPDATE `Projects` SET `eng_name` = 'SAICAr and S-Ado' WHERE `Projects`.`Id` = 17;
# UPDATE `Projects` SET `eng_name` = 'Acylcarnitines' WHERE `Projects`.`Id` = 18;
# UPDATE `Projects` SET `eng_name` = 'Borreliosis Confirmation' WHERE `Projects`.`Id` = 19;
# #########


inst = Institution.find_by(nip: "5252821696")

contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "epiexpert@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

ApiAccount.create!(username: "epixpert", password: "mn4FRPp9TcbWssEK", password_confirmation: "mn4FRPp9TcbWssEK", contractor_id: contractor.Id)




inst = Institution.create!(name: "Nume", nip: "DE360207124", address: "Stadtbahnstraße 118 d, 22391 Hamburg", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "Stadtbahnstraße 118 d, 22391 Hamburg", street: "Stadtbahnstraße 118 d", postal_code: "22391", city: "Hamburg", company_for_shipments: nil, shipment_street: "Stadtbahnstraße 118 d", shipment_postal_code: "22391", shipment_city: "Hamburg", region_of_activity: 0 )

contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "nume@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

ApiAccount.create!(username: "nume", password: "TphNtt2YnhbmgNfw", password_confirmation: "TphNtt2YnhbmgNfw", contractor_id: contractor.Id)