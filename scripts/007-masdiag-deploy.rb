inst = Institution.find 1

contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "api@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

# development
ApiAccount.create!(username: "masdiag_zdTGLeznGv3N89vy", password: "DRr89cd7AfTM6gk4gbn27H754HYhnjL2", password_confirmation: "DRr89cd7AfTM6gk4gbn27H754HYhnjL2", contractor_id: contractor.Id)

# production
# ApiAccount.create!(username: "masdiag_yEt5mA7cFvnJMQY8", password: "TEXCCEXmwMpeqT5WaL5pXrMrP3u9tSMt", password_confirmation: "TEXCCEXmwMpeqT5WaL5pXrMrP3u9tSMt", contractor_id: contractor.Id)
