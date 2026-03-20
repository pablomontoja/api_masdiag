class Session < ApplicationRecord
  belongs_to :contractor

  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end
