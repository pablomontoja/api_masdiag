class Toxo::Sample < ApplicationRecord
  self.table_name = "Samples"
  self.primary_key = "Id"

  attribute :project_ids, default: []

  enum :MaterialType, MaterialTypes::MODEL_HASH
  enum :post_examination_procedure, { immediate_return: 0, storage_and_return: 1, storage_and_disposal: 2 }
  enum :infectious_risk, { no_information: 0, elevated: 1 }
  enum :execution_mode, { standard: 0, expedited: 1 }

  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  has_many :measurements, class_name: "Measurement", foreign_key: "SampleId", dependent: :destroy, inverse_of: :sample

  before_validation -> { self.Code&.upcase! }
  before_validation :set_defaults
  after_commit :set_rsc

  validates :Code, presence: true, uniqueness: true
  validates :RegistrationDate, presence: true
  validates :SampleState, presence: true
  validates :SampleStatus, presence: true
  validates :MaterialType, presence: true
  validates :WrongRegistrationStatus, presence: true
  validates_inclusion_of :IsWrongRegistration, in: [true, false]
  validates_inclusion_of :WasWrongRegistration, in: [true, false]
  validates :post_examination_procedure, presence: true
  validates :infectious_risk, presence: true
  validates :execution_mode, presence: true

  validate :code_must_belong_to_contractor_institution
  validate :code_must_not_be_already_registered
  validate :project_ids_presence

  scope :toxo, -> {
    joins(:measurements).where(measurements: { ProjectId: Toxo::Constants::TOXO_PROJECT_IDS }).distinct
  }

  def deletable?
    self.AcceptanceDate.nil?
  end

  def accepted_in_lab?
    !self.AcceptanceDate.nil?
  end

  private

  def set_defaults
    self.payment_status  = 1
    self.access_hash     = "toxo-#{SecureRandom.urlsafe_base64}" if self.access_hash.blank?
    self.RegistrationDate = DateTime.now if self.new_record?
    self.IsWrongRegistration  ||= false
    self.WasWrongRegistration ||= false
    self.WrongRegistrationStatus ||= 0
    self.SampleStatus ||= 1
    self.SampleState  ||= 1
    self.IsControlSample  = false if self.IsControlSample.nil?
    self.IsAuthWithoutResult = false if self.IsAuthWithoutResult.nil?
    self.IsSentBack = false if self.IsSentBack.nil?
  end

private

  def code_must_belong_to_contractor_institution
    institution_id = self.patient&.contractor&.institution_id
    return if institution_id.nil?
    unless ReservedSampleCode.exists?(Code: self.Code, InstitutionId: institution_id)
      errors.add(:Code, "not_in_pool")
    end
  end

  def code_must_not_be_already_registered
    # byebug
    if Sample.where(Code: self.Code).where.not(Id: self.Id).exists?
      errors.add(:Code, "already_registered")
    end
  end

  def project_ids_presence
    # byebug
    errors.add(:project_ids, "no_tests_selected") if self.project_ids.empty?
  end

  def set_rsc
    return if destroyed?
    r = ReservedSampleCode.find_by(Code: self.Code)
    self.update_column(:reserved_sample_code_id, r.Id) unless r.nil? || self.reserved_sample_code_id.present?
  end
end
