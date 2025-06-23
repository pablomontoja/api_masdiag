# == Schema Information
#
# Table name: online_files
#
#  measurement_id                 :integer          not null, primary key
#  filename                       :text(4294967295)
#  content_type                   :text(4294967295)
#  file_size                      :integer          not null
#  file_contents                  :binary(429496729
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  is_notification_send           :boolean          default(FALSE), not null
#  is_patient_notification_send   :boolean          default(FALSE), not null
#  password                       :string(255)
#  when_notification_send         :datetime
#  when_patient_notification_send :datetime
#  encrypted_file_size            :integer          not null
#  encrypted_file_contents        :binary(429496729
#
class OnlineFile < ApplicationRecord
  self.primary_key = "measurement_id"

  belongs_to :measurement

  has_one_attached :encrypted_result
  has_one_attached :unencrypted_result

  # def readonly?
  #   Rails.env.test? ? false : true
  # end
  
  def prepare_active_storage
    encrypted_result.attach(io: StringIO.new(encrypted_file_contents), filename: filename, content_type: content_type) unless encrypted_result.attached? || encrypted_file_contents.nil?
    unencrypted_result.attach(io: StringIO.new(file_contents), filename: filename, content_type: content_type) unless unencrypted_result.attached? || file_contents.nil?
    # puts "#{filename} - Active Storage successfully synchronized"
  end

  def force_prepare_active_storage
    encrypted_result.attach(io: StringIO.new(encrypted_file_contents), filename: filename, content_type: content_type) unless encrypted_file_contents.nil?
    unencrypted_result.attach(io: StringIO.new(file_contents), filename: filename, content_type: content_type) unless file_contents.nil?    
  end

end
