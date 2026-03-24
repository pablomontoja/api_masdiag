class Toxo::Sample < ApplicationRecord
  self.table_name = "Samples"
  self.primary_key = "Id"

  enum :MaterialType, MaterialTypes::MODEL_HASH
  enum :post_examination_procedure, { immediate_return: 0, storage_and_return: 1, storage_and_disposal: 2 }
  enum :infectious_risk, { no_information: 0, elevated: 1 }
  enum :execution_mode, { standard: 0, expedited: 1 }

  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  has_many :measurements, class_name: "Measurement", foreign_key: "SampleId", dependent: :destroy, inverse_of: :sample

  before_validation -> { self.Code&.upcase! }
  before_save :set_defaults

  validates :Code, presence: true, uniqueness: true
  validates :RegistrationDate, presence: true
  validates :SampleState, presence: true
  validates :SampleStatus, presence: true
  validates :MaterialType, presence: true
  validates :WrongRegistrationStatus, presence: true
  validates_inclusion_of :IsWrongRegistration, in: [true, false]
  validates_inclusion_of :WasWrongRegistration, in: [true, false]

  scope :toxo, -> {
    joins(:measurements).where(measurements: { ProjectId: Toxo::Constants::TOXO_PROJECT_IDS }).distinct
  }

  def deletable?
    AcceptanceDate.nil?
  end

  def accepted_in_lab?
    !AcceptanceDate.nil?
  end

  private

  def set_defaults
    self.payment_status  = 1
    self.access_hash     = SecureRandom.urlsafe_base64 if access_hash.blank?
    self.RegistrationDate = DateTime.now if new_record?
    self.IsWrongRegistration  ||= false
    self.WasWrongRegistration ||= false
    self.WrongRegistrationStatus ||= 0
    self.SampleStatus ||= 1
    self.SampleState  ||= 1
    self.IsControlSample  = false if IsControlSample.nil?
    self.IsAuthWithoutResult = false if IsAuthWithoutResult.nil?
    self.IsSentBack = false if IsSentBack.nil?
  end
end
