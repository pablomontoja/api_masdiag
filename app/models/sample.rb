class Sample < ApplicationRecord
  before_validation -> { self.Code.upcase! }

  self.table_name = "Samples"
  self.primary_key = "Id"
  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  has_many :measurements, class_name: 'Measurement', foreign_key: 'SampleId', dependent: :destroy, inverse_of: :sample
  accepts_nested_attributes_for :patient
  has_many :test_transactions

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
    fv1_sample.validates :Code, length: { minimum: 5, maximum: 10 }
  end

  validates :sample_collection_date, presence: true, comparison: { less_than_or_equal_to: :today_date }
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
    [4,5].include?(soaking_degree_id) || SampleStatus == 4
  end

  #######################
  private
  #######################

  def today_date
    Date.today
  end

  def set_defaults
    self.payment_status = 1
    self.access_hash = SecureRandom.urlsafe_base64
    self.RegistrationDate = DateTime.now if self.new_record?
  end
end
