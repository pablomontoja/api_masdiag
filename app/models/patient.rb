class Patient < ApplicationRecord
  self.table_name = "Patients"
  self.primary_key = "Id"
  attr_accessor :email_confirmation
  belongs_to :contractor, class_name: "Contractor", foreign_key: "ContractorId"
  has_many :samples, class_name: "Sample", foreign_key: "PatientId", dependent: :destroy

  # callbacks
  before_save :set_time_stamps
  # before_save :set_gender_and_birthday, if: Proc.new { |patient| patient.Pesel.present? }
  before_save :update_data_from_pesel, if: Proc.new { |patient| patient.Pesel.present? && Activepesel::Pesel.new(patient.Pesel).valid? }
  before_validation :strip_fields

  # validations
  validates :FirstName, presence: true, length: { minimum: 2 }
  validates :LastName, presence: true, length: { minimum: 2 }
  validates :Pesel, presence: true, length: { is: 11 }, uniqueness: { scope: :ContractorId }, unless: Proc.new { |patient| patient.Gender.present? && patient.BirthDate.present? && patient.id_document.present? && patient.id_number.present? }
  validate :pesel_validation, unless: Proc.new { |patient| patient.Gender.present? && patient.BirthDate.present? && patient.id_document.present? && patient.id_number.present? }
  validates :Gender, presence: true, if: Proc.new { |patient| patient.Pesel.blank? }
  validates :BirthDate, presence: true, comparison: { less_than_or_equal_to: Date.today }, if: Proc.new { |patient| patient.Pesel.blank? }
  validates :id_document, presence: true, if: Proc.new { |patient| patient.Pesel.blank? }
  validates_inclusion_of :id_document, in: V1::Common::IDENTITY_DOCUMENTS.keys, message: "%{value} is not in the list of possible documents, see GET /v1/common/identity_documents", if: Proc.new { |patient| patient.Pesel.blank? }
  validates :id_number, presence: true, length: { minimum: 2 }, if: Proc.new { |patient| patient.Pesel.blank? }


  def fullname
    "#{self.FirstName} #{self.LastName}"
  end

  private

  def strip_fields
    self.FirstName.strip!
    self.LastName.strip!
    self.id_number.strip!
    self.Pesel.strip!
  end

  def pesel_validation
    errors.add(:Pesel, "is invalid") unless Activepesel::Pesel.new(self.Pesel).valid?
  end

  def update_data_from_pesel
    pesel = Activepesel::Pesel.new(self.Pesel)
    self.BirthDate = pesel.date_of_birth
    self.Gender = pesel.sex - 1 # js activepesel uses 1, 2 codes for gender whereas our app uses 0, 1
  end

  def set_time_stamps
    self.CreatedAt = DateTime.now if self.new_record?
    self.RegistrationDate = DateTime.now if self.new_record?
    self.ModifiedAt = DateTime.now
    self.send_results_on_mail = true
    self.IsVirtual = false
  end

end
