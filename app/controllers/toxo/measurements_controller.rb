class Toxo::MeasurementsController < Toxo::BaseController
  include Toxo::Sortable
  include Toxo::Searchable
  include Toxo::Paginatable

  SORTABLE_COLUMNS = {
    "sample_code"   => "Samples.Code",
    "lot"           => "Samples.Lot",
    "level"         => "Samples.Level",
    "authorized_at" => "Measurements.AuthorizedAt",
    "dispatch_date" => "Samples.dispatch_date",
    "project"       => "Measurements.ProjectId"
  }.freeze

  SEARCHABLE_COLUMNS = %w[Samples.Code Samples.Lot].freeze

  before_action :set_measurement, only: :show

  # GET /toxo/measurements
  def index
    scoped = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
    scoped = apply_sort(apply_search(scoped))
    @measurements, meta = paginate(scoped)
    render json: { data: @measurements.map { |m| serialize_measurement(m) }, meta: meta }
  end

  # GET /toxo/measurements/:id
  def show
    authorize @measurement, policy_class: Toxo::MeasurementPolicy
    render json: serialize_measurement(@measurement)
  end

  private

  def set_measurement
    @measurement = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

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


# == Schema Information
#
# Table name: Measurements
#
#  Id                :integer          not null, primary key
#  SampleId          :integer          not null
#  ProjectId         :integer          not null
#  ResultId          :integer
#  IsRepeat          :boolean          default(FALSE), not null
#  Status            :integer          not null
#  MeasureDate       :datetime
#  IsValid           :boolean          default(FALSE), not null
#  LabCode           :text(4294967295)
#  CreatedById       :integer
#  CreatedAt         :datetime
#  ModifiedById      :integer
#  ModifiedAt        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  AuthorizedById    :integer
#  AuthorizedAt      :datetime
#  CuttedAt          :datetime
#  selected_analytes :text(65535)
#  InstrumentId      :integer
#  MaterialType      :integer          default(0), not null
#