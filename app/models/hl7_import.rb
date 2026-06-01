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
