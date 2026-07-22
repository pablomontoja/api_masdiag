module Toxo
  module MeasurementSerialization
    extend ActiveSupport::Concern

    private

    def serialize_measurement(measurement)
      {
        Id:          measurement.Id,
        SampleId:    measurement.SampleId,
        ProjectId:   measurement.ProjectId,
        Status:      measurement.Status,
        IsRepeat:    measurement.IsRepeat,
        AuthorizedAt: measurement.AuthorizedAt,
        SampleCode:   measurement.sample.Code,
        SampleLot:   measurement.sample.Lot,
        SampleLevel:   measurement.sample.Level,
        SampleMaterialType: measurement.sample.MaterialType,
        SampleDispatchDate: measurement.sample.dispatch_date,
        SampleState: measurement.sample.SampleState,
        report_pdf_url: unencrypted_result_url(measurement),
        has_on_request_measurement: measurement.sample.measurements.exists?(ProjectId: 42)
      }
    end

    def unencrypted_result_url(measurement)
      return nil unless measurement&.online_file&.file_contents&.present?

      measurement.online_file.prepare_active_storage
      url_for(measurement.online_file.unencrypted_result)
    end
  end
end
