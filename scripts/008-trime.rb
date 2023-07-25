###################
# staging
###################
inst = Institution.create!(name: "Trime", nip: "CZ01815148", address: "Národní 135/14, Praha 110 00", wants_summary_of_performed_samples: false, auto_test_charge: false, has_disabled_invoices: true, shipping_address: "Národní 135/14, Praha 110 00", street: "Národní 135/14", postal_code: "110 00", city: "Praha", company_for_shipments: nil, shipment_street: "Národní 135/14", shipment_postal_code: "110 00", shipment_city: "Praha", region_of_activity: 0 )

contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "trime@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

ApiAccount.create!(username: "trime", password: "LXD4Ds4qEssAsZg2", password_confirmation: "LXD4Ds4qEssAsZg2", contractor_id: contractor.Id, language: "en")