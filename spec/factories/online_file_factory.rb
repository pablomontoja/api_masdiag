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
FactoryBot.define do
  factory :online_file, class: OnlineFile do
    measurement
    file_size { 0 }
    content_type { "Application/pdf" }
    encrypted_file_size { 0 }
    # sample_collection_date { Date.today }
  end
end
