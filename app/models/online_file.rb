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
    puts "#{filename} - Active Storage successfully synchronized"
  end

end
