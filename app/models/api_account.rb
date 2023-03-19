class ApiAccount < ApplicationRecord
  include ActiveModel::SecurePassword
  has_secure_password :password, validations: false

  # attribute :settings, :text, default: "{}"
  serialize :settings, type: Hash, coder: JSON, default: Hash.new

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true

  belongs_to :contractor
  has_one :institution, through: :contractor

  def errors
    super.tap { |errors| errors.delete(:password, :blank) if Current.api_account }
  end


  def result_post_endpoint
    self.settings["result_post_endpoint"] || ""
  end

  def result_post_endpoint=(url)
    self.settings["result_post_endpoint"] = url
    self.save
  end

end
