module Webhook
  class ScannedDocsController < ActionController::API
      include Response
      include ExceptionHandler
      include ActiveStorage::SetCurrent

      before_action :authenticate_webhook!

      def create
        result = ScannedDocs::Ingestor.new(ingest_params, params[:file]).call

        if result.success?
          json_response({ status: result.status, id: result.scanned_doc_id }, :accepted)
        else
          json_response({ error: result.error }, :unprocessable_content)
        end
      end

      private

      def ingest_params
        params.permit(:source_filename, :page_checksum, :document_key,
                      :captured_at, :sample_id, :source)
      end

      def authenticate_webhook!
        provided = request.authorization.to_s.delete_prefix("Bearer ")
        expected = Rails.application.credentials.dig(:scan_webhook, :token).to_s
        return if expected.present? &&
                  ActiveSupport::SecurityUtils.secure_compare(provided, expected)

        json_response({ error: "unauthorized" }, :unauthorized)
      end
  end
end
