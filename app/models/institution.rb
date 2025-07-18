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
#
class Institution < ApplicationRecord
  has_many :contractors, class_name: "Contractor", foreign_key: "institution_id"
  has_many :patients, through: :contractors

  # belongs_to :discount, optional: true
  # belongs_to :agent, foreign_key: "created_by_agent_id", optional: true
  # has_and_belongs_to_many :projects, join_table: "institutions_projects"

  # before_validation :remove_whitespaces_and_dashes_in_nip

  # validates :name, presence: true, uniqueness: true
  # validates :nip, presence: true, uniqueness: true, length: { is: 10 }, if: Proc.new { |i| i.region_of_activity == 0 }
  # validates :email, presence: true, if: Proc.new { |i| i.approve_contractor_after_registration }

  def fullname
    case self.kind
    when "Hospital"
      "#{self.name} - NIP #{self.nip} - Szpitalne"
    when "ForeignInstitution"
      "#{self.name} - Instytucja Zagraniczna #{self.nip}"
    else
      "#{self.name} - NIP #{self.nip}"
    end
  end

  # def readonly?
  #   Rails.env.test? ? false : true
  # end

  def available_codes
    rsc_codes = ReservedSampleCode.where(InstitutionId: self.id).pluck(:Code)
    scodes = Sample.where(Code: rsc_codes).pluck(:Code)
    (rsc_codes - scodes)
  end

  def not_assigned_codes
    rscs = ReservedSampleCode.where(InstitutionId: self.id).pluck(:Id)
    reserved = ReservedTest.where(reserved_sample_code_id: rscs).pluck(:reserved_sample_code_id)
    ReservedSampleCode.where(Id: (rscs - reserved)).pluck(:Code)
  end

  def api_contractor_id
    Contractor.where(institution_id: self.id).find_by("first_name LIKE ?", "API%")&.Id
  end

  private

  # def remove_whitespaces_and_dashes_in_nip
  #   nip.strip!
  #   nip.gsub!(/[^0-9]/, "")
  # end

end
