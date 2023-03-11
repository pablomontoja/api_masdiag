class Sample < ApplicationRecord
  before_validation -> { self.Code.upcase! }

  self.table_name = "Samples"
  self.primary_key = "Id"
  belongs_to :patient, class_name: "Patient", foreign_key: "PatientId"
  has_many :measurements, class_name: 'Measurement', foreign_key: 'SampleId', dependent: :destroy, inverse_of: :sample
  accepts_nested_attributes_for :patient
  has_many :answers, class_name: 'Answer', foreign_key: "Sample_id", dependent: :destroy, inverse_of: :sample

  attr_accessor :approve

  # callbacks
  before_save :set_defaults

  # walidacja
  validates :Code, presence: true, uniqueness: true
  validates :Code, length: { is: 5 }
  validates :sample_collection_date, presence: true, comparison: { less_than_or_equal_to: Date.today }
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

  def self.search(search)
    if search.present?
      a = self.where("Code LIKE ?", "%#{search}%").collect(&:id)
      a = a + self.joins(:patient).where("FirstName LIKE ? or LastName LIKE ?", "%#{search}%", "%#{search}%").collect(&:id)
      self.where(id: a).all
      #self.where("number LIKE ? or sample_name LIKE ? or comment LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%").all
    else
      self.all
    end
  end

  def set_defaults
    self.payment_status = 1
    self.access_hash = SecureRandom.urlsafe_base64
    self.RegistrationDate = DateTime.now if self.new_record?
  end
end
