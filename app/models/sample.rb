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
#  post_examination_procedure :integer          default(0), not null
#  infectious_risk            :integer          default(0), not null
#  execution_mode             :integer          default(0), not null
#
class Sample < ApplicationRecord
  before_validation -> { self.Code.upcase! }

  enum :MaterialType, MaterialTypes::MODEL_HASH

  self.table_name = "Samples"
  self.primary_key = "Id"
  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  belongs_to :soaking_degree, optional: true
  has_many :measurements, class_name: 'Measurement', foreign_key: 'SampleId', dependent: :destroy, inverse_of: :sample
  accepts_nested_attributes_for :patient
  has_many :test_transactions # in labpanel here is has_one used
  has_many :notes, as: :subject

  attr_accessor :approve

  # callbacks
  before_save :set_defaults

  # walidacja
  validates :Code, presence: true, uniqueness: true

  with_options({on: :v1}) do |v1_sample|
    v1_sample.validates :Code, length: { is: 5 }
  end

  # TODO - fv1 validation of Code length - it need to be tested
  with_options({on: :fv1}) do |fv1_sample|
    fv1_sample.validates :Code, length: { minimum: 5, maximum: 20 }
  end

  validates :sample_collection_date, presence: true
  validate :sample_collection_date_range
  validates :RegistrationDate, presence: true
  validates_inclusion_of :IsWrongRegistration, in: [true, false]
  validates_inclusion_of :WasWrongRegistration, in: [true, false]
  validates :SampleState, presence: true
  validates :SampleStatus, presence: true
  validates :MaterialType, presence: true
  validates :WrongRegistrationStatus, presence: true

  def rsc
    ReservedSampleCode.find_by(Code: self.Code)
  end

  def hasResult?
    authorized_count = self.measurements.where(Status: 5).size
    authorized_count > 0 ? true : false
  end

  def test_names
    measurements.map{|m| m.project&.Name}
  end

  def cancelled?
    [4,5].include?(soaking_degree_id) || self.SampleStatus == 4
  end

  def accepted_in_lab?
    !self.AcceptanceDate.nil?
  end

  #######################
  private
  #######################

  def today_date
    Date.today
  end

  def sample_collection_date_range
    return unless sample_collection_date.present?

    reference_date = accepted_in_lab? ? self.AcceptanceDate.to_date : Date.today
    earliest = reference_date - 6.weeks

    if sample_collection_date > reference_date
      errors.add(:sample_collection_date, :less_than_or_equal_to, count: reference_date)
    elsif sample_collection_date < earliest
      errors.add(:sample_collection_date, :greater_than_or_equal_to, count: earliest)
    end
  end

  def set_defaults
    self.payment_status = 1
    self.access_hash = SecureRandom.urlsafe_base64
    self.RegistrationDate = DateTime.now if self.new_record?
  end
end
