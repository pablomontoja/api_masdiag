# == Schema Information
#
# Table name: hl7_imports
#
#  id                  :bigint           not null, primary key
#  measurement_id      :integer
#  s3_key              :string(255)      not null
#  s3_bucket           :string(255)
#  s3_etag             :string(255)
#  file_size           :integer
#  control_id          :string(255)
#  message_type        :string(255)
#  message_datetime    :datetime
#  sending_application :string(255)
#  sending_facility    :string(255)
#  external_order_id   :string(255)
#  hl7_test_code       :string(255)
#  kit_code_extracted  :string(255)
#  status              :integer          default(0), not null
#  processed_at        :datetime
#  error_message       :text(65535)
#  processing_stats    :text(65535)
#  retry_count         :integer          default(0)
#  last_retry_at       :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Hl7Import < ApplicationRecord
  belongs_to :measurement,
             class_name: "Measurement",
             foreign_key: :measurement_id,
             primary_key: "Id",
             optional: true

  has_one_attached :hl7_file

  enum :status, {
    pending:               0,
    processing:            1,
    completed:             2,
    failed:                3,
    awaiting_registration: 4,
    registration_error:    5,
    retry_scheduled:       6
  }

  scope :ready_for_retry, -> { where(status: :failed).where("retry_count < 3") }

  def mark_completed!(stats)
    update!(status: :completed, processed_at: Time.current, processing_stats: stats.to_json)
  end

  def mark_failed!(message)
    update!(status: :failed, error_message: message)
  end

  def mark_awaiting_registration!(reason)
    update!(status: :awaiting_registration, error_message: reason)
  end

  def mark_registration_error!(reason)
    update!(status: :registration_error, error_message: reason)
  end
end
