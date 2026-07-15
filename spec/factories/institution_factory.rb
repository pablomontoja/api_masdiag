# == Schema Information
#
# Table name: institutions
#
#  id                                    :integer          not null, primary key
#  name                                  :string(255)
#  address                               :text(65535)
#  nip                                   :string(255)
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  allow_patient_email                   :boolean          default(FALSE), not null
#  has_approve_messages_for_patients     :boolean          default(FALSE), not null
#  has_payment_status_in_samples         :boolean          default(FALSE), not null
#  logo_file                             :binary(16777215)
#  krs                                   :string(255)
#  regon                                 :string(255)
#  has_disabled_invoices                 :boolean          default(FALSE), not null
#  approve_contractor_after_registration :boolean          default(FALSE), not null
#  email                                 :string(255)
#  created_by_agent_id                   :integer
#  wants_summary_of_performed_samples    :boolean
#  footer_phone_and_email                :text(4294967295)
#  patient_email_template_body           :text(65535)
#  contractor_email_template_body        :text(65535)
#  inivitation_jpg_image                 :binary(16777215)
#  email_attachment_pdf                  :binary(16777215)
#  custom_cbx_text_in_sample_form        :text(65535)
#  smtp_settings_name                    :string(255)
#  smtp_email                            :string(255)
#  test_alert_treshold                   :integer
#  shipping_address                      :text(65535)
#  terms_accepted                        :boolean
#  terms_accepted_at                     :datetime
#  auto_test_charge                      :boolean
#  electronic_invoice_acceptance         :boolean
#  electronic_invoice_accepted_at        :datetime
#  terms_version                         :string(255)
#  street                                :string(255)
#  postal_code                           :string(255)
#  city                                  :string(255)
#  company_for_shipments                 :string(255)
#  shipment_street                       :string(255)
#  shipment_postal_code                  :string(255)
#  shipment_city                         :string(255)
#  kind                                  :string(255)      default("Institution"), not null
#  email_for_results                     :string(255)
#  assigned_masdiag_bban                 :string(255)      default("09 2490 0005 0000 4530 4006 9262")
#  days_for_payment                      :integer
#  email_for_notifications               :string(255)
#  short_name                            :string(255)
#
FactoryBot.define do
  factory :institution, class: Institution do
    name { "Masdiag Sp. z o.o." }
    address { "ul. Żeromskiego 33, 01-882 Warszawa"}
    nip { "5222996468" }
    # region_of_activity { 0 }
  end
end



# "id":"1"
# "name":"Masdiag Sp. z o.o."
# "address":"ul. Żeromskiego 33, 01-882 Warszawa"
# "nip":"5222996468"
# "created_at":"2016-10-16 00:00:00"
# "updated_at":"2022-04-03 14:29:57"
# "allow_patient_email":"1"
# "has_approve_messages_for_patients":"1"
# "has_payment_status_in_samples":"1"
# "krs":"0000420325"
# "regon":"146121549"
# "discount_id":null
# "has_disabled_invoices":"1"
# "approve_contractor_after_registration":"0"
# "email":"masdiag@masdiag.pl"
# "created_by_agent_id":null
# "region_of_activity":"0"
# "wants_summary_of_performed_samples":"0"
# "footer_phone_and_email":null
# "patient_email_template_body":null
# "contractor_email_template_body":null
# "inivitation_jpg_image":null
# "email_attachment_pdf":null
# "custom_cbx_text_in_sample_form":null
# "smtp_settings_name":null
# "smtp_email":null
# "test_alert_treshold":"20"
# "shipping_address":"ul. Żeromskiego 33, 01-882 Warszawa"
# "terms_accepted":"1"
# "terms_accepted_at":"2022-04-03 14:29:57"
# "auto_test_charge":"1"
# "electronic_invoice_acceptance":null
# "electronic_invoice_accepted_at":null
# "terms_version":"04_31.03.2022_01"
# "street":"ul. Żeromskiego 33"
# "postal_code":"01-882"
# "city":"Warszawa"
# "company_for_shipments":null
# "shipment_street":"ul. Żeromskiego 33"
# "shipment_postal_code":"01-882"
# "shipment_city":"Warszawa"
