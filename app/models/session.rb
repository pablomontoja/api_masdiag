# == Schema Information
#
# Table name: sessions
#
#  id             :bigint           not null, primary key
#  contractor_id  :integer          not null
#  ip_address     :string(255)
#  user_agent     :string(255)
#  token          :string(255)      not null
#  last_active_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Session < ApplicationRecord
  belongs_to :contractor

  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end
