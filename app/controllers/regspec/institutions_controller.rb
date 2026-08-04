class Regspec::InstitutionsController < ApplicationController
	include MasdiagCheck

	# regspec_institutions POST   /regspec/institutions 
	def create
		inst = Institution.new(creation_params)
		if inst.save
			json_response({ institution_id: inst.id }, :created)
		else
			json_response({ message: inst.errors.map(&:message).join(", ") }, :unprocessable_content)
		end		
	end


	# regspec_institution PATCH  /regspec/institutions/:id
	def update
		inst = Institution.find(params[:id])
		if inst.update(update_params)
			json_response({})
		else
			json_response({ message: inst.errors.map(&:message).join(", ") }, :unprocessable_content)
		end
	end


	private

  #  REGSPEC has the following attributes of institution
	#  id             :bigint 
	#  name           :string(255)
	#  street_address :string(255)
	#  postal_code    :string(255)
	#  city           :string(255)
	#  nip            :string(255)
	#
	def institution_params
		params.require(:institution).permit(:name, :street_address, :postal_code, :city, :nip)		
	end

	def creation_params
		ip = institution_params
		ip.merge!(
			address: "#{ ip[:street_address] }, #{ ip[:postal_code] }, #{ ip[:city] }", 
			allow_patient_email: false, 
			has_approve_messages_for_patients: false, 
			has_payment_status_in_samples: false, 
			logo_file: nil, 
			krs: nil, 
			regon: nil,
			has_disabled_invoices: true, 
			approve_contractor_after_registration: false, 
			email: nil, 
			created_by_agent_id: nil, 
			wants_summary_of_performed_samples: false, 
			footer_phone_and_email: nil, 
			patient_email_template_body: nil, 
			contractor_email_template_body: nil, 
			inivitation_jpg_image: nil, 
			email_attachment_pdf: nil, 
			custom_cbx_text_in_sample_form: nil, 
			smtp_settings_name: nil, 
			smtp_email: nil, 
			test_alert_treshold: nil,
			shipping_address: "#{ ip[:street_address] }, #{ ip[:postal_code] }, #{ ip[:city] }", 
			terms_accepted: nil, 
			terms_accepted_at: nil, 
			auto_test_charge: false, 
			electronic_invoice_acceptance: nil, 
			electronic_invoice_accepted_at: nil, 
			terms_version: nil, 
			street: "#{ ip[:street_address] }",
			company_for_shipments: nil, 
			shipment_street: "#{ ip[:street_address] }", 
			shipment_postal_code: "#{ ip[:postal_code] }", 
			shipment_city: "#{ ip[:city] }", 
			kind: "Hospital", 
			email_for_results: nil
		).except(:street_address)
	end

	def update_params
		ip = institution_params
		ip.merge!(
			address: "#{ ip[:street_address] }, #{ ip[:postal_code] }, #{ ip[:city] }",			
			shipping_address: "#{ ip[:street_address] }, #{ ip[:postal_code] }, #{ ip[:city] }",
			street: "#{ ip[:street_address] }",
			shipment_street: "#{ ip[:street_address] }", 
			shipment_postal_code: "#{ ip[:postal_code] }", 
			shipment_city: "#{ ip[:city] }"
		).except(:street_address)
	end

end