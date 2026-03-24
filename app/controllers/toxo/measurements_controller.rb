class Toxo::MeasurementsController < Toxo::BaseController
  before_action :set_measurement, only: :show

  # GET /toxo/measurements
  def index
    @measurements = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
    render json: @measurements.map { |m| serialize_measurement(m) }
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
      MaterialType: measurement.MaterialType,
      IsRepeat:    measurement.IsRepeat,
      MeasureDate: measurement.MeasureDate,
      IsValid:     measurement.IsValid
    }
  end
end
