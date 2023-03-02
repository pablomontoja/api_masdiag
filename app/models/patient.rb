class Patient < ApplicationRecord	
	self.table_name = "Patients"
	self.primary_key = "Id"
  attr_accessor :email_confirmation
  belongs_to :contractor, class_name: "Contractor", foreign_key: "ContractorId"
  has_many :samples, class_name: "Sample", foreign_key: "PatientId", dependent: :destroy

  # callbacks
  before_save :set_time_stamps
  before_save :set_gender_and_birthday

  # walidacja
  validates :FirstName, presence: true
  validates :LastName, presence: true
  validates :Pesel, presence: true, uniqueness: { scope: :ContractorId }, unless: Proc.new { |patient| patient.is_foreigner == true }
  validates :id_document, presence: true, unless: Proc.new { |patient| patient.is_foreigner == false }
  validates :id_number, presence: true, unless: Proc.new { |patient| patient.is_foreigner == false }

  def fullname
    "#{self.FirstName} #{self.LastName}"
  end
  

private 

  def set_gender_and_birthday
    if self.is_foreigner == false
      pesel = Activepesel::Pesel.new(self.Pesel)

      case pesel.sex
        when 1        
          self.Gender = 0 #facet
        when 2        
          self.Gender = 1 #baba
      end

      if pesel.valid?
        self.BirthDate = pesel.date_of_birth
      else
        self.BirthDate = nil
      end
      
      self.id_number = nil
      self.id_document = nil
    else
      self.Pesel = nil
    end   
    
  end

  def set_time_stamps
    self.CreatedAt = DateTime.now if self.new_record?
    self.RegistrationDate = DateTime.now if self.new_record?
    self.ModifiedAt = DateTime.now
    self.send_results_on_mail = true
    self.IsVirtual = false;
  end
  
end
