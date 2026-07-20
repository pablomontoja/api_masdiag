# == Schema Information
#
# Table name: Contractors
#
#  Id                         :integer          not null, primary key
#  Name                       :text(4294967295)
#  Address                    :text(4294967295)
#  created_at                 :datetime
#  updated_at                 :datetime
#  email                      :string(255)      default(""), not null
#  encrypted_password         :string(255)      default(""), not null
#  reset_password_token       :string(255)
#  reset_password_sent_at     :datetime
#  remember_created_at        :datetime
#  sign_in_count              :integer          default(0), not null
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  first_name                 :string(255)
#  last_name                  :string(255)
#  nip                        :string(255)
#  approved                   :boolean          default(FALSE), not null
#  are_notifications_enabled  :boolean          default(FALSE), not null
#  type_of_contractor         :integer          default(0), not null
#  institution_id             :integer
#  agent_id                   :integer
#  phone                      :string(255)
#  invalid_first_or_last_name :boolean          not null
#  patient_is_orderer         :boolean          not null
#  is_super_contractor        :boolean          default(FALSE)
#  can_add_samples            :boolean          default(TRUE)
#  confirmed_at               :datetime
#  confirmation_sent_at       :datetime
#  confirmation_token         :string(255)
#  unconfirmed_email          :string(255)
#  creator_id                 :integer
#  locale                     :string(255)      default("pl"), not null
#  allow_sample_acceptance_notifications  :boolean         default(TRUE), not null
#  allow_sample_rejection_notifications   :boolean         default(TRUE), not null
#  allow_result_notifications             :boolean         default(TRUE), not null
#  allow_sample_registration_notifications :boolean        default(TRUE), not null
#
class Contractor < ApplicationRecord
  self.table_name = "Contractors"
  self.primary_key = "Id"

  has_many :patients, class_name: "Patient", foreign_key: "ContractorId", dependent: :destroy
  has_many :samples, through: :patients, class_name: "Sample", foreign_key: "PatientId"
  belongs_to :institution, optional: true
  has_one :api_account

  def fullname
    "#{first_name} #{last_name}"
  end

  def can_add_samples?
    can_add_samples == true
  end

  def is_super_contractor?
    is_super_contractor == true
  end

  # Returns or creates the dedicated toxo patient for this contractor.
  def patient
    Patient.find_or_initialize_by(ContractorId: self.Id, FirstName: "PACJENT", LastName: "TOXO").tap do |p|
      if p.new_record?
        p.Gender = 0
        p.BirthDate = 20.years.ago
        p.save!
      end
    end
  end

  # def readonly?
  #   Rails.env.test? ? false : true
  # end

end
