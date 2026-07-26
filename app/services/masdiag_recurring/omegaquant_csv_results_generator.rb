module MasdiagRecurring
  class OmegaquantCsvResultsGenerator < ApplicationService

    def initialize(meas_ids)
      @meas_ids = meas_ids
    end

    def call
      institution = Institution.find_by!(name: "OmegaQuant Analytics")
      codes = ReservedSampleCode.where(InstitutionId: institution.id).pluck(:Code)

      @r_ids = Result.includes(measurement: :sample)
                     .where(measurement: { Id: @meas_ids, Status: 5, Samples: { IsControlSample: false, Code: codes } })
                     .order(MeasurementId: :desc)
                     .limit(1000)
                     .pluck(:MeasurementId)

      @analyte_ids = AnalyteResult.where(ResultId: @r_ids).pluck(:AnalyteId).uniq
      analytes = Analyte.where(Id: @analyte_ids).index_by(&:Id)
      @sorted_analytes = @analyte_ids.map { |id| analytes[id] }

      csv = generate_csv

      handle_result({ csv: csv, measurement_ids: @r_ids })
    rescue StandardError => e
      Sentry.capture_exception(e)
      handle_error(e)
    end

    private

    def generate_csv
      analyte_index = @analyte_ids.each_with_index.to_h
      analyte_results_lookup = build_analyte_results_lookup

      CSV.generate(col_sep: "\t") do |csv|
        header = ["Sample code"] + @sorted_analytes.map { |a| "#{a.NameInAPI} [#{a.Unit}]" }
        csv << header

        Result.includes(measurement: :sample)
              .where(MeasurementId: @r_ids)
              .find_in_batches(batch_size: 100) do |group|
          group.each do |res|
            csv << build_row(res, analyte_results_lookup, analyte_index)
          end
        end
      end
    end

    # Builds { result_id => { analyte_id => value } } in a single query.
    def build_analyte_results_lookup
      AnalyteResult
        .where(ResultId: @r_ids)
        .pluck(:ResultId, :AnalyteId, :Value)
        .each_with_object(Hash.new { |h, k| h[k] = {} }) do |(result_id, analyte_id, value), hash|
          hash[result_id][analyte_id] = value
        end
    end

    def build_row(res, analyte_results_lookup, analyte_index)
      sample_code = res.measurement.sample.Code

      analyte_values = Array.new(@analyte_ids.size)
      analyte_results_lookup[res.MeasurementId].each do |analyte_id, value|
        idx = analyte_index[analyte_id]
        analyte_values[idx] = value if idx
      end

      [sample_code] + analyte_values
    end

  end
end
