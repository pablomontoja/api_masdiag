###################
# staging
###################
ActiveRecord::Base.transaction do
	inst = Institution.create!(name: "OmegaQuant Analytics", address: "4600 W. Nobel St., Ste 123 | Sioux Falls, SD 57107", nip: "---??---", created_at: "2026-02-25 10:21:24", updated_at: "2026-02-25 10:21:24", allow_patient_email: false, has_approve_messages_for_patients: false, has_payment_status_in_samples: false, logo_file: nil, krs: nil, regon: nil, has_disabled_invoices: true, approve_contractor_after_registration: false, email: nil, created_by_agent_id: nil, wants_summary_of_performed_samples: false, footer_phone_and_email: nil, patient_email_template_body: nil, contractor_email_template_body: nil, inivitation_jpg_image: nil, email_attachment_pdf: nil, custom_cbx_text_in_sample_form: nil, smtp_settings_name: nil, smtp_email: nil, test_alert_treshold: nil, shipping_address: "-", terms_accepted: nil, terms_accepted_at: nil, auto_test_charge: false, electronic_invoice_acceptance: nil, electronic_invoice_accepted_at: nil, terms_version: nil, street: "-", postal_code: "-", city: "-", company_for_shipments: nil, shipment_street: "-", shipment_postal_code: "-", shipment_city: "-", kind: "ForeignInstitution", email_for_results: "jason@omegaquant.com")

	contractor = Contractor.create!(first_name: "API", last_name: "MASDIAG", email: "omegaquant.analytics@masdiag.pl", institution_id: inst.id, is_super_contractor: false, invalid_first_or_last_name: true, patient_is_orderer: true, can_add_samples: true, confirmed_at: Time.zone.now, are_notifications_enabled: false)

	ApiAccount.create!(username: "omegaquant.analytics", password: "hu0dWYguk4XjJXDbng3g", password_confirmation: "hu0dWYguk4XjJXDbng3g", contractor_id: contractor.Id, language: "en")
end
