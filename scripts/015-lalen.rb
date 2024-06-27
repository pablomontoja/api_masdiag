###################
# dev
###################
ActiveRecord::Base.transaction do
  # LALEN AU
	inst = Institution.find(85)
	contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "lalen-au@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)
	api_acc = ApiAccount.create!(username: "lalenAU", password: "fwUnMrCZdX9TFc2x", password_confirmation: "fwUnMrCZdX9TFc2x", contractor_id: contractor.Id, language: "en")
	Current.api_account = ApiAccount.find_by(username: "lalenAU")
	Current.api_account.result_post_endpoint="http://127.0.0.1:3000/api/results"
	Current.api_account.result_post_endpoint_username = Rails.application.credentials.lalenportalapi.username
	Current.api_account.result_post_endpoint_password = Rails.application.credentials.lalenportalapi.password

	# LALEN EU
	# inst_eu = Institution.find(89)	
	# contractor_eu = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "lalen-eu@masdiag.pl", institution_id: inst_eu.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)	
	# api_acc_eu = ApiAccount.create!(username: "lalenEU", password: "jeHnBPK62uS4MFWp", password_confirmation: "jeHnBPK62uS4MFWp", contractor_id: contractor_eu.Id, language: "en")
	# Current.api_account = ApiAccount.find_by(username: "lalenEU")
	# Current.api_account.result_post_endpoint="http://127.0.0.1:3000/api/results"
	# Current.api_account.result_post_endpoint_username = Rails.application.credentials.lalenportalapi.username
	# Current.api_account.result_post_endpoint_password = Rails.application.credentials.lalenportalapi.password
end


