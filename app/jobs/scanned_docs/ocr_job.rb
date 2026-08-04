module ScannedDocs
  class OcrJob < ApplicationJob
    queue_as :ocr

    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(scanned_doc_id)
      doc = ScannedDoc.find(scanned_doc_id)
      return unless doc.page_pdf.attached?
      return if doc.transcribed?

      doc.update!(status: :ocr_pending, ocr_started_at: Time.current)

      png_bytes = ScannedDocs::PageRasterizer.new(doc.page_pdf).to_png_bytes
      markdown  = ScannedDocs::OcrClient.new.transcribe(png_bytes)

      doc.markdown.attach(
        io:           StringIO.new(markdown),
        filename:     "#{doc.page_checksum}.md",
        content_type: "text/markdown"
      )
      doc.update!(status: :transcribed, transcribed_at: Time.current)
    rescue => e
      doc&.update(status: :failed, processing_error: e.message)
      raise
    end
  end
end
