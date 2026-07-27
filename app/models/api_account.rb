# == Schema Information
#
# Table name: api_accounts
#
#  id                  :bigint           not null, primary key
#  username            :string(255)
#  password_digest     :string(255)
#  contractor_id       :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  settings_ciphertext :text(65535)
#  language            :string(255)      default("pl"), not null
#
class ApiAccount < ApplicationRecord
  include ActiveModel::SecurePassword
  has_secure_password :password, validations: false

  after_initialize :init_settings

  # serialize :settings, type: Hash, coder: JSON, default: Hash.new
  has_encrypted :settings, type: :hash #, migrating: true
  
  self.ignored_columns = ["settings"]

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

  def result_post_endpoint_credentials
    self.settings["result_post_endpoint_username"].blank? || self.settings["result_post_endpoint_password"].blank? ? nil : OpenStruct.new(username: self.settings["result_post_endpoint_username"], password: self.settings["result_post_endpoint_password"])
  end

  def result_post_endpoint_username=(username)
    self.settings["result_post_endpoint_username"] = username
    self.save
  end

  def result_post_endpoint_password=(password)    
    self.settings["result_post_endpoint_password"] = password
    self.save
  end

  private

  def init_settings
    self.settings ||= {}
  end
end
