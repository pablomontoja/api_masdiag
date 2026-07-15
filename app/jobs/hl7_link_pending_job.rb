class Hl7LinkPendingJob < ApplicationJob
  queue_as :background

  def perform
    result = Hl7::PendingImportLinker.new.link_pending_imports
    Rails.logger.info("[HL7 Link Pending] linked=#{result[:linked]} waiting=#{result[:waiting]} errors=#{result[:errors].count}")
    Rails.logger.warn("[HL7 Link Pending] Errors: #{result[:errors].join('; ')}") if result[:errors].any?
  end
end
