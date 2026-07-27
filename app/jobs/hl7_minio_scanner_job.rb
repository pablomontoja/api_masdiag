class Hl7MinioScannerJob < ApplicationJob
  queue_as :background

  def perform
    return if Rails.env.development?
    result = Hl7::MinioScanner.new.scan_and_import
    Rails.logger.info("[Hl7MinioScannerJob] new_files=#{result[:new_files]}, errors=#{result[:errors].count}")
    if result[:errors].any?
      Rails.logger.warn("[Hl7MinioScannerJob] Errors: #{result[:errors].join('; ')}")
    end
  end
end
