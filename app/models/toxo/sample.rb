# == Schema Information
#
# Table name: Samples
#
#  Id                         :integer          not null, primary key
#  Code                       :string(50)       not null
#  ProtocolName               :text(4294967295)
#  IsControlSample            :boolean          default(FALSE), not null
#  IsWrongRegistration        :boolean          default(FALSE), not null
#  IsSentBack                 :boolean          default(FALSE), not null
#  SentBackDate               :datetime
#  Description                :text(4294967295)
#  RegistrationDate           :datetime
#  IsValid                    :boolean          default(TRUE), not null
#  PatientId                  :integer
#  UserId                     :integer
#  IsAuthWithoutResult        :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  payment_status             :integer
#  AcceptanceDate             :datetime
#  access_hash                :string(255)
#  sample_collection_date     :datetime
#  soaking_degree_id          :integer
#  WasWrongRegistration       :boolean          not null
#  MaterialType               :integer          not null
#  SampleStatus               :integer          not null
#  SampleState                :integer          not null
#  Comment                    :text(4294967295)
#  CancellationDate           :datetime
#  ArchivingDate              :datetime
#  WrongRegistrationStatus    :integer          not null
#  CancelledById              :integer
#  UtilizationDate            :datetime
#  Lot                        :text(255)
#  Level                      :text(255)
#  selected_tests             :text(65535)
#  clinical_info              :text(65535)
#  reserved_sample_code_id    :integer
#  dispatch_date              :datetime
#  post_examination_procedure :integer          default("immediate_return"), not null
#  infectious_risk            :integer          default("no_information"), not null
#  execution_mode             :integer          default("standard"), not null
#
class Toxo::Sample < ApplicationRecord
  self.table_name = "Samples"
  self.primary_key = "Id"

  attribute :project_ids, default: []

  enum :MaterialType, MaterialTypes::MODEL_HASH
  enum :post_examination_procedure, { immediate_return: 0, storage_and_return: 1, storage_and_disposal: 2 }
  enum :infectious_risk, { no_information: 0, elevated: 1 }
  enum :execution_mode, { standard: 0, expedited: 1 }

  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  belongs_to :reserved_sample_code, optional: true
  has_many :measurements, class_name: "Measurement", foreign_key: "SampleId", dependent: :destroy, inverse_of: :sample

  before_validation -> { self.Code&.upcase! }
  before_validation -> { self.RegistrationDate = Time.current.to_date }
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
  validate :sample_collection_date_not_in_future
  validate :project_ids_presence, on: :create

  scope :toxo, -> {
    joins(:measurements).where(measurements: { ProjectId: Toxo::Constants::TOXO_PROJECT_IDS }).distinct
  }

  def deletable?
    self.AcceptanceDate.nil?
  end

  def accepted_in_lab?
    !self.AcceptanceDate.nil?
  end

  def rsc
    self.reserved_sample_code
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
      errors.add(:Code, :not_in_pool)
    end
  end

  def code_must_not_be_already_registered
    # byebug
    if Sample.where(Code: self.Code).where.not(Id: self.Id).exists?
      errors.add(:Code, :already_registered)
    end
  end

  def project_ids_presence
    # byebug
    errors.add(:project_ids, :no_tests_selected) if self.project_ids.empty?
  end

  def sample_collection_date_not_in_future
    return if sample_collection_date.blank?
    errors.add(:sample_collection_date, :cannot_be_in_future) if sample_collection_date.to_date > Date.current
  end

  def set_rsc
    return if destroyed?
    r = ReservedSampleCode.find_by(Code: self.Code)
    self.update_column(:reserved_sample_code_id, r.Id) unless r.nil? || self.reserved_sample_code_id.present?
  end
end
