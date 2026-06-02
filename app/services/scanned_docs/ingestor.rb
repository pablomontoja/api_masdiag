module ScannedDocs
  class Ingestor
    Result = Struct.new(:success, :status, :scanned_doc_id, :error, keyword_init: true) do
      def success? = success
    end

    PDF_MAGIC = "%PDF-".b

    def initialize(params, file)
      @params = params
      @file   = file
    end

    def call
      validate!

      doc = ScannedDoc.find_or_initialize_by(page_checksum: @params[:page_checksum])
      if doc.persisted? && doc.page_pdf.attached?
        return Result.new(success: true, status: "duplicate", scanned_doc_id: doc.id)
      end

      doc.assign_attributes(
        source_filename: @params[:source_filename],
        document_key:    @params[:document_key],
        sample_id:       resolved_sample_id,
        captured_at:     parse_captured_at,
        source:          @params[:source].presence || "scan_watcher",
        received_at:     Time.current,
        status:          :ready
      )
      doc.save!
      doc.page_pdf.attach(
        io:           @file.tempfile,
        filename:     @file.original_filename,
        content_type: "application/pdf"
      )

      ScannedDocs::OcrJob.perform_later(doc.id)
      Result.new(success: true, status: "stored", scanned_doc_id: doc.id)
    rescue ActiveRecord::RecordNotUnique
      existing = ScannedDoc.find_by!(page_checksum: @params[:page_checksum])
      Result.new(success: true, status: "duplicate", scanned_doc_id: existing.id)
    rescue => e
      Result.new(success: false, error: e.message)
    end

    private

    def validate!
      raise "no file uploaded"       unless @file.respond_to?(:tempfile)
      raise "page_checksum required" if @params[:page_checksum].blank?
      raise "file too large"         if @file.size > 25.megabytes
      raise "not a PDF"              unless File.binread(@file.tempfile.path, 5) == PDF_MAGIC
    end

    def resolved_sample_id
      id = @params[:sample_id].presence
      return nil unless id && Sample.exists?(id)
      id
    end

    def parse_captured_at
      raw = @params[:captured_at].presence
      return nil unless raw
      Time.parse(raw)
    rescue ArgumentError
      nil
    end
  end
end
