class Contractor < ApplicationRecord
  self.table_name = "Contractors"
  self.primary_key = "Id"

  has_many :patients, class_name: "Patient", foreign_key: "ContractorId", dependent: :destroy
  has_many :samples, through: :patients, class_name: "Sample", foreign_key: "PatientId"
  belongs_to :institution

  def fullname
    "#{first_name} #{last_name}"
  end

  # def readonly?
  #   Rails.env.test? ? false : true
  # end

end
