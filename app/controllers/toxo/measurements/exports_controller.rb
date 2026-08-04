class Toxo::Measurements::ExportsController < Toxo::BaseController
  include Toxo::MeasurementSerialization

  # GET /toxo/measurements/exports
  def index
    from = parse_date(params[:authorized_at_from])
    to   = parse_date(params[:authorized_at_to])

    if from.nil? || to.nil?
      render json: { error: "authorized_at_from and authorized_at_to are required" }, status: :unprocessable_content
      return
    end

    if from > to
      render json: { error: "authorized_at_from must be before or equal to authorized_at_to" }, status: :unprocessable_content
      return
    end

    measurements = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
                     .where(AuthorizedAt: from.beginning_of_day..to.end_of_day)
                     .order(:AuthorizedAt)

    render json: {
      data: measurements.map { |m| serialize_measurement(m) },
      meta: { authorized_at_from: from.to_s, authorized_at_to: to.to_s, total_count: measurements.size }
    }
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
