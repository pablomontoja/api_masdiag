class Toxo::Samples::ExportsController < Toxo::BaseController
  # GET /toxo/samples/exports
  def index
    from = parse_date(params[:dispatch_date_from])
    to   = parse_date(params[:dispatch_date_to])

    if from.nil? || to.nil?
      render json: { error: "dispatch_date_from and dispatch_date_to are required" }, status: :unprocessable_entity
      return
    end

    if from > to
      render json: { error: "dispatch_date_from must be before or equal to dispatch_date_to" }, status: :unprocessable_entity
      return
    end

    samples = policy_scope(Toxo::Sample.all, policy_scope_class: Toxo::SamplePolicy::Scope)
                .where(dispatch_date: from.beginning_of_day..to.end_of_day)
                .order(:dispatch_date, :Code)

    render json: {
      data: samples.map { |s| serialize_export_row(s) },
      meta: { dispatch_date_from: from.to_s, dispatch_date_to: to.to_s, total_count: samples.size }
    }
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def serialize_export_row(sample)
    {
      Code: sample.Code,
      Lot: sample.Lot,
      RegistrationDate: sample.RegistrationDate,
      dispatch_date: sample.dispatch_date
    }
  end
end
