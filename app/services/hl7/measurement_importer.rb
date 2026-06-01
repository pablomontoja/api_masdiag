module Hl7
  class MeasurementImporter
    CREATININE_IDENTIFIERS = %w[UCR CrSpUr usCr].freeze

    attr_reader :errors, :warnings, :stats

    def initialize(hl7_import)
      @hl7_import  = hl7_import
      @measurement = hl7_import.measurement
      @project_id  = Hl7::Config::TEST_MAPPING[hl7_import.hl7_test_code]
      @errors      = []
      @warnings    = []
      @stats       = { analytes_created: 0, analytes_skipped: 0, comments_skipped: 0 }
    end

    def import
      @hl7_import.update!(status: :processing)
      @succeeded = false

      ActiveRecord::Base.transaction do
        load_and_parse_hl7
        unless valid_after_parse?
          @failure_reason = @errors.join("; ")
          raise ActiveRecord::Rollback
        end

        extract_message_metadata
        creatinine_mmol_l = extract_creatinine

        if creatinine_mmol_l.nil? && requires_creatinine_conversion?
          @failure_reason = "Creatinine value missing or unparseable — required for Project #{@project_id} absolute conversion"
          raise ActiveRecord::Rollback
        end

        analyte_rows = process_obx_segments(creatinine_mmol_l)

        if @errors.any?
          @failure_reason = @errors.join("; ")
          raise ActiveRecord::Rollback
        end

        result = find_or_create_result
        save_analyte_results(result, analyte_rows)
        update_measurement_status

        @stats[:warnings] = @warnings if @warnings.any?
        @hl7_import.mark_completed!(@stats)
        @succeeded = true
      end

      if @failure_reason
        @hl7_import.mark_failed!(@failure_reason)
        return false
      end

      return false unless @succeeded

      archive_file_in_minio
      true
    rescue StandardError => e
      @errors << "#{e.class}: #{e.message}"
      @hl7_import.mark_failed!(@errors.join("; "))
      Rails.logger.error("[HL7 Importer] Failed measurement #{@measurement&.id}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      false
    end

    private

    def load_and_parse_hl7
      hl7_content = @hl7_import.hl7_file.download
      normalized  = hl7_content.strip.tr("\n", "\r")
      @parsed     = HL7::Message.new(normalized)
      @msh        = @parsed[:MSH]
      @obr        = @parsed[:OBR]
      @obx_segments = @parsed.select { |s| s.is_a?(HL7::Message::Segment::OBX) }
    rescue StandardError => e
      @errors << "Failed to parse HL7: #{e.message}"
      @msh = nil
      @obr = nil
      @obx_segments = []
    end

    def valid_after_parse?
      @errors << "Missing MSH segment" unless @msh
      @errors << "Missing OBR segment" unless @obr
      @errors << "No OBX observations found" if @obx_segments&.empty?
      @errors.empty?
    end

    def extract_message_metadata
      @hl7_import.update!(
        control_id:          @msh[10].to_s,
        message_type:        @msh[9].to_s,
        message_datetime:    parse_hl7_datetime(@msh[7].to_s),
        sending_application: @msh[3].to_s,
        sending_facility:    @msh[4].to_s,
        external_order_id:   @obr[3].to_s.split("^").first
      )
    end

    def extract_creatinine
      creatinine_obx = @obx_segments.find do |obx|
        obx[2].to_s == "NM" && CREATININE_IDENTIFIERS.include?(obx[3].to_s.split("^").first.strip)
      end
      return nil unless creatinine_obx

      mmol_l = obx_numeric_value(creatinine_obx[5].to_s)
      return nil unless mmol_l

      # Store converted mg/dl value via standard analyte processing below;
      # return raw mmol/L for metal back-conversion
      mmol_l
    end

    def requires_creatinine_conversion?
      # Project 32 metals require absolute µg/L which needs creatinine back-conversion
      @project_id == 32
    end

    def process_obx_segments(creatinine_mmol_l)
      creatinine_g_per_l = creatinine_mmol_l ? creatinine_mmol_l * Hl7::Config::CREATININE_MOLAR_MASS / 1000.0 : nil
      rows = []

      @obx_segments.each do |obx|
        value_type = obx[2].to_s

        if value_type == "FT"
          @stats[:comments_skipped] += 1
          next
        end

        next unless value_type == "NM"

        hl7_code = obx[3].to_s.split("^").first.strip

        # Creatinine OBX: store as mg/dl in DB; mmol/L back-conversion was already extracted separately
        if CREATININE_IDENTIFIERS.include?(hl7_code) && creatinine_mmol_l
          db_name = Hl7::Config::ANALYTE_MAPPING[hl7_code]
          if db_name
            mg_dl   = creatinine_mmol_l * Hl7::Config::CREATININE_MOLAR_MASS / 10.0
            analyte = find_analyte(db_name)
            if analyte
              rows << { AnalyteId: analyte.id, Value: mg_dl.round(4), MeasuredValue: mg_dl.round(5), Unit: analyte.Unit }
              @stats[:analytes_created] += 1
            end
          end
          next
        end
        next if CREATININE_IDENTIFIERS.include?(hl7_code) # skip if no creatinine_mmol_l

        # Direct-store identifiers (e.g. uIodEx): HL7 value stored as-is in DB
        if Hl7::Config::DIRECT_STORE_IDENTIFIERS.include?(hl7_code)
          db_name = Hl7::Config::ANALYTE_MAPPING[hl7_code]
          if db_name
            value   = obx_numeric_value(obx[5].to_s)
            analyte = find_analyte(db_name)
            if analyte && value
              rows << { AnalyteId: analyte.id, Value: value.round(4), MeasuredValue: value.round(5), Unit: analyte.Unit }
              @stats[:analytes_created] += 1
            else
              warn_skipped(hl7_code, value ? "analyte '#{db_name}' not found" : "unparseable value")
            end
          end
          next
        end

        # UG_PER_L direct identifiers (e.g. UR-IODINE): value is ug/L → store as ng/ml (1:1)
        if Hl7::Config::UG_PER_L_DIRECT_IDENTIFIERS.include?(hl7_code)
          db_name = Hl7::Config::ANALYTE_MAPPING[hl7_code]
          next unless db_name

          value = obx_numeric_value(obx[5].to_s)
          next warn_skipped(hl7_code, "unparseable value") unless value

          analyte = find_analyte(db_name)
          next warn_skipped(hl7_code, "analyte '#{db_name}' not found in project #{@project_id}") unless analyte

          rows << { AnalyteId: analyte.id, Value: value.round(4), MeasuredValue: value.round(5), Unit: analyte.Unit }
          @stats[:analytes_created] += 1
          next
        end

        # Standard analytes: raw absolute (µg/L) and optional _crea variant
        raw_db_name  = Hl7::Config::ANALYTE_MAPPING[hl7_code]
        crea_db_name = Hl7::Config::ANALYTE_MAPPING["#{hl7_code}_crea"]

        unless raw_db_name
          warn_skipped(hl7_code, "no mapping")
          next
        end

        hl7_value = obx_numeric_value(obx[5].to_s)
        next warn_skipped(hl7_code, "unparseable value") unless hl7_value

        obx_unit = obx[6].to_s.strip.downcase  # "ug/gcr" or "mg/gcr"

        # Raw absolute: convert ug/gCR → µg/L (or mg/gCR → µg/L with ×1000 factor)
        if creatinine_g_per_l
          unit_factor = obx_unit.include?("mg") ? 1000.0 : 1.0
          absolute_value = hl7_value * unit_factor * creatinine_g_per_l

          analyte = find_analyte(raw_db_name)
          if analyte
            rows << { AnalyteId: analyte.id, Value: absolute_value.round(4), MeasuredValue: absolute_value.round(5), Unit: analyte.Unit }
            @stats[:analytes_created] += 1
          else
            warn_skipped(hl7_code, "analyte '#{raw_db_name}' not found in project #{@project_id}")
          end
        end

        # _crea variant: store raw HL7 value directly (ug/gCR or mg/gCR as-is)
        if crea_db_name
          analyte = find_analyte(crea_db_name)
          if analyte
            rows << { AnalyteId: analyte.id, Value: hl7_value.round(4), MeasuredValue: hl7_value.round(5), Unit: analyte.Unit }
            @stats[:analytes_created] += 1
          else
            warn_skipped("#{hl7_code}_crea", "analyte '#{crea_db_name}' not found in project #{@project_id}")
          end
        end
      end

      rows
    end

    def find_or_create_result
      result = Result.find_by(MeasurementId: @measurement.id)
      return result if result

      Result.create!(
        MeasurementId: @measurement.id,
        ImportDate:    Time.current,
        IsValid:       true,
        ImportUserId:  Hl7::Config::SYSTEM_USER_ID
      )
    end

    def save_analyte_results(result, rows)
      AnalyteResult.where(ResultId: result.MeasurementId).delete_all

      if rows.any?
        records = rows.map do |row|
          row.merge(ResultId: result.MeasurementId, Result_MeasurementId: result.MeasurementId)
        end
        AnalyteResult.insert_all(records)
      end
    end

    def update_measurement_status
      @measurement.update!(Status: 4, MeasureDate: Time.current)
    end

    def archive_file_in_minio
      s3_client = Aws::S3::Client.new(
        access_key_id:     Rails.application.credentials.dig(:hl7_s3, :access_key_id),
        secret_access_key: Rails.application.credentials.dig(:hl7_s3, :secret_access_key),
        endpoint:          Rails.application.credentials.dig(:hl7_s3, :endpoint),
        force_path_style:  true,
        region:            "eu-central-1"
      )

      source_key  = @hl7_import.s3_key
      archive_key = "#{Hl7::Config::ARCHIVE_FOLDER}/#{File.basename(source_key)}"

      s3_client.copy_object(
        bucket:      @hl7_import.s3_bucket,
        copy_source: "#{@hl7_import.s3_bucket}/#{source_key}",
        key:         archive_key
      )
      s3_client.delete_object(bucket: @hl7_import.s3_bucket, key: source_key)

      Rails.logger.info("[HL7 Importer] Archived: #{source_key} → #{archive_key}")
    rescue StandardError => e
      Rails.logger.error("[HL7 Importer] Archive failed for #{@hl7_import.s3_key}: #{e.message}")
    end

    def find_analyte(name_in_api)
      Analyte.find_by(NameInAPI: name_in_api, ProjectId: @project_id)
    end

    def warn_skipped(code, reason)
      @warnings << "Skipped OBX #{code}: #{reason}"
      @stats[:analytes_skipped] += 1
    end

    def obx_numeric_value(value_str)
      cleaned = value_str.to_s.strip.tr(",", ".")
      Float(cleaned)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_hl7_datetime(str)
      return nil if str.blank?
      clean = str.gsub(/[+\-]\d{4}$/, "")
      DateTime.strptime(clean, "%Y%m%d%H%M%S")
    rescue ArgumentError
      nil
    end
  end
end
