class Hl7RetryFailedJob < ApplicationJob
  queue_as :background

  def perform
    count = 0
    Hl7Import.ready_for_retry.find_each do |hl7_import|
      hl7_import.update!(
        status:        :retry_scheduled,
        retry_count:   hl7_import.retry_count + 1,
        last_retry_at: Time.current
      )
      Hl7::MeasurementImportJob.perform_later(hl7_import.id)
      count += 1
    end
    Rails.logger.info("[HL7 Retry Failed] Enqueued #{count} retries")
  end
end
