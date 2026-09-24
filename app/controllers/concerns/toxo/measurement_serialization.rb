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
        report_pdf_url: measurement.report_pdf_url,
        has_on_request_measurement: measurement.sample.measurements.exists?(ProjectId: 42),
        has_chromatogram_request: measurement.notes.exists?(key: Toxo::Constants::CHROMATOGRAM_REQUEST_NOTE_KEY)
      }
    end
  end
end
