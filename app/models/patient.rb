# == Schema Information
#
# Table name: Patients
#
#  Id                    :integer          not null, primary key
#  RegistrationDate      :datetime         not null
#  FirstName             :text(4294967295) not null
#  LastName              :text(4294967295) not null
#  Pesel                 :text(4294967295)
#  BirthDate             :datetime         not null
#  Gender                :integer          not null
#  ContractorId          :integer          not null
#  CreatedById           :integer
#  CreatedAt             :datetime
#  ModifiedById          :integer
#  ModifiedAt            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  email                 :string(255)
#  phone                 :string(255)
#  is_foreigner          :boolean          default(FALSE), not null
#  approve1              :boolean          default(FALSE)
#  approve2              :boolean          default(FALSE)
#  approve3              :boolean          default(FALSE)
#  language              :string(255)      default("pl"), not null
#  approve_personal_data :boolean          default(FALSE)
#  IsVirtual             :boolean          not null
#  send_results_on_mail  :boolean          default(FALSE), not null
#  body_weight           :string(255)
#  body_height           :string(255)
#  id_document           :integer
#  id_number             :string(255)
#
class Patient < ApplicationRecord
  include Patients::FoodForTheBrainModificator

  self.table_name = "Patients"
  self.primary_key = "Id"
  attr_accessor :email_confirmation
  belongs_to :contractor, class_name: "Contractor", foreign_key: "ContractorId"
  has_many :samples, class_name: "Sample", foreign_key: "PatientId", dependent: :destroy

  # callbacks
  before_save :set_time_stamps
  before_save :update_data_from_pesel, if: Proc.new { |patient| patient.Pesel.present? && Activepesel::Pesel.new(patient.Pesel).valid? }
  before_validation :strip_fields

  # validations
  validates :FirstName, presence: true, length: { minimum: 2 }
  validates :LastName, presence: true, length: { minimum: 2 }

  # v1 validations
  with_options({on: :v1}) do |v1_patient|
    v1_patient.validates :Pesel, presence: true, length: { is: 11 }, uniqueness: { scope: :ContractorId }, unless: Proc.new { |patient| patient.Gender.present? && patient.BirthDate.present? && patient.id_document.present? && patient.id_number.present? }
    v1_patient.validate :pesel_validation, unless: Proc.new { |patient| patient.Gender.present? && patient.BirthDate.present? && patient.id_document.present? && patient.id_number.present? && patient.Pesel.blank? }
    v1_patient.validates :Gender, presence: true, if: Proc.new { |patient| patient.Pesel.blank? }
    v1_patient.validates :BirthDate, presence: true, comparison: { less_than_or_equal_to: :today_date }, if: Proc.new { |patient| patient.Pesel.blank? }
    v1_patient.validates :id_document, presence: true, if: Proc.new { |patient| patient.Pesel.blank? }
    v1_patient.validates_inclusion_of :id_document, in: V1::Common::IDENTITY_DOCUMENTS.keys, message: "%{value} is not in the list of possible documents, see GET /v1/common/identity_documents", if: Proc.new { |patient| patient.Pesel.blank? }
    v1_patient.validates :id_number, presence: true, length: { minimum: 2 }, if: Proc.new { |patient| patient.Pesel.blank? }
  end

  # NUME validations
  with_options({on: :fv1}) do |nume_patient|
    nume_patient.validates :Gender, presence: true
    nume_patient.validates_inclusion_of :Gender, in: [0, 1], message: "%{value} is not in the list of possible values (0 for male and 1 for female)"
    nume_patient.validates :BirthDate, presence: true, comparison: { less_than_or_equal_to: :today_date }
  end

  def fullname
    "#{self.FirstName} #{self.LastName}"
  end

  #######################
  private
  #######################

  def today_date
    Date.today
  end

  def strip_fields
    self.FirstName&.strip!
    self.LastName&.strip!
    self.id_number&.strip!
    self.Pesel&.strip!
  end

  def pesel_validation
    errors.add(:Pesel, "is invalid") unless Activepesel::Pesel.new(self.Pesel).valid?
  end

  def update_data_from_pesel
    pesel = Activepesel::Pesel.new(self.Pesel)
    self.BirthDate = pesel.date_of_birth
    self.Gender = pesel.sex - 1 # js activepesel uses 1, 2 codes for gender whereas our app uses 0, 1
  end

# TODO - I think that send_results_on_mail shouldn't be here in set_time_stamps method because it is trigerred before each save
  def set_time_stamps
    self.CreatedAt = DateTime.now if self.new_record?
    self.RegistrationDate = DateTime.now if self.new_record?
    self.ModifiedAt = DateTime.now
    self.send_results_on_mail = true
    self.IsVirtual = false
  end

end
