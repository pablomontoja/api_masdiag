class ApiAccount < ApplicationRecord
  has_secure_password
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true

  belongs_to :contractor
  has_one :institution, through: :contractor

end
