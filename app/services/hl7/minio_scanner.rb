module Hl7
  class MinioScanner
    attr_reader :new_files_count, :errors

    def initialize
      @s3_client = Aws::S3::Client.new(
        access_key_id:     Rails.application.credentials.dig(:hl7_s3, :access_key_id),
        secret_access_key: Rails.application.credentials.dig(:hl7_s3, :secret_access_key),
        endpoint:          Rails.application.credentials.dig(:hl7_s3, :endpoint),
        force_path_style:  true,
        region:            "eu-central-1"
      )           

      @bucket          = Rails.application.credentials.dig(:hl7_s3, :bucket)
      @new_files_count = 0
      @errors          = []
    end

    def scan_and_import
      Rails.logger.info("[HL7 MinIO Scanner] Starting scan of #{@bucket}")

      list_new_files.each { |obj| process_s3_file(obj) }

      Rails.logger.info("[HL7 MinIO Scanner] Completed. New files: #{@new_files_count}, Errors: #{@errors.count}")
      { new_files: @new_files_count, errors: @errors }
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error("[HL7 MinIO Scanner] MinIO Error: #{e.message}")
      @errors << "MinIO Error: #{e.message}"
      { new_files: 0, errors: @errors }
    end

    private

    def list_new_files
      response     = @s3_client.list_objects_v2(bucket: @bucket)
      imported_keys = Hl7Import.pluck(:s3_key)

      response.contents.reject do |obj|
        obj.key.end_with?("/") || # Skip directories
        obj.key.start_with?("#{Hl7::Config::ARCHIVE_FOLDER}/") || # Skip archive folder
        imported_keys.include?(obj.key) # Skip already imported
      end
    end

    def process_s3_file(s3_object)
      Rails.logger.info("[HL7 MinIO Scanner] Processing: #{s3_object.key}")

      response    = @s3_client.get_object(bucket: @bucket, key: s3_object.key)
      hl7_content = response.body.read
      parsed_data = parse_hl7_metadata(hl7_content)
     

      unless parsed_data[:kit_code]
        @errors << "Could not extract kit code from #{s3_object.key}"
        return
      end

      unless parsed_data[:test_code]
        @errors << "Could not extract test code from #{s3_object.key}"
        return
      end

      hl7_import = create_hl7_import(s3_object, parsed_data, hl7_content)
      return unless hl7_import

      measurement = find_measurement_for_import(parsed_data)

      if measurement
        link_and_process(hl7_import, measurement)
      else
        mark_as_awaiting_registration(hl7_import, parsed_data)
      end

      @new_files_count += 1
    rescue StandardError => e
      Rails.logger.error("[HL7 MinIO Scanner] Error processing #{s3_object.key}: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      @errors << "#{s3_object.key}: #{e.message}"
    end

    def create_hl7_import(s3_object, parsed_data, hl7_content)
      hl7_import = Hl7Import.create!(
        s3_key:             s3_object.key,
        s3_bucket:          @bucket,
        s3_etag:            s3_object.etag,
        file_size:          s3_object.size,
        kit_code_extracted: parsed_data[:kit_code],
        hl7_test_code:      parsed_data[:test_code],
        status:             :pending
      )

      hl7_import.hl7_file.attach(
        io:           StringIO.new(hl7_content),
        filename:     File.basename(s3_object.key),
        content_type: "text/plain"
      )

      hl7_import
    rescue StandardError => e
      @errors << "Failed to create Hl7Import for #{s3_object.key}: #{e.message}"
      nil
    end

    def find_measurement_for_import(parsed_data)
      kit_code   = parsed_data[:kit_code]
      test_code  = parsed_data[:test_code]
      project_id = Hl7::Config::TEST_MAPPING[test_code]
      return nil unless project_id

      sample = Sample.find_by(Code: kit_code)
      return nil unless sample

      sample.measurements.find_by(ProjectId: project_id)
    end

    def link_and_process(hl7_import, measurement)
      if measurement.hl7_import.present? && measurement.hl7_import.id != hl7_import.id
        Rails.logger.info("[HL7 MinIO Scanner] Measurement #{measurement.Id} already has HL7 import, marking as registration_error")
        hl7_import.mark_registration_error!("Measurement already has HL7 import")
        return
      end

      hl7_import.update!(measurement_id: measurement.Id, status: :pending)
      Hl7::MeasurementImportJob.perform_later(hl7_import.id)
      Rails.logger.info("[HL7 MinIO Scanner] Linked and enqueued: #{hl7_import.s3_key} → Measurement #{measurement.Id}")
    end

    def mark_as_awaiting_registration(hl7_import, parsed_data)
      reason = "Sample '#{parsed_data[:kit_code]}' not registered yet for test '#{parsed_data[:test_code]}'"
      hl7_import.mark_awaiting_registration!(reason)
      Rails.logger.info("[HL7 MinIO Scanner] Marked as awaiting registration: #{hl7_import.s3_key}")
    end

    def parse_hl7_metadata(hl7_content)
      parsed = HL7::Message.parse(hl7_content)

      kit_code = parsed[:OBR][13].to_s.strip
      kit_code = parsed[:PID][5].to_s.split('^').first.to_s.strip if kit_code.blank?
      kit_code = nil if kit_code.blank?

      # Extract test code from OBR[4]
      test_code = parsed[:OBR][4].to_s&.split('^').first

      {
        kit_code: kit_code,
        test_code: test_code&.strip
      }
    rescue StandardError => e
      Rails.logger.error("[HL7 MinIO Scanner] Failed to parse HL7 metadata: #{e.message}")
      { kit_code: nil, test_code: nil }
    end
  end
end
