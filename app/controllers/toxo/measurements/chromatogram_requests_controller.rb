class Toxo::Measurements::ChromatogramRequestsController < Toxo::BaseController
  NOTE_KEY = Toxo::Constants::CHROMATOGRAM_REQUEST_NOTE_KEY

  # POST /toxo/measurements/:measurement_id/chromatogram_requests
  def create
    measurement = policy_scope(Measurement, policy_scope_class: Toxo::MeasurementPolicy::Scope)
                    .find(params[:measurement_id])
    authorize measurement, :request_chromatogram?, policy_class: Toxo::MeasurementPolicy

    unless Toxo::Constants::CHROMATOGRAM_REQUEST_INSTITUTION_IDS.include?(current_contractor.institution_id)
      return render_forbidden
    end

    unless measurement.ProjectId.in?([ 39, 41 ]) && (measurement.Status == 5 || measurement.AuthorizedAt.present?)
      return render json: { errors: { base: [ "Measurement is not eligible for a chromatogram request" ] } },
                    status: :unprocessable_content
    end

    note = measurement.notes.find_by(key: NOTE_KEY)
    if note
      return render json: { status: "already_requested" }, status: :ok
    end

    note = measurement.notes.create!(key: NOTE_KEY, description: notification_body(measurement))
    Toxo::SampleNotificationMailer.chromatogram_request(measurement, current_contractor).deliver_now

    render json: { status: "requested" }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  private

  def notification_body(measurement)
    "Prośba o chromatogram — kontrahent: #{current_contractor.email}, kod próbki: " \
      "#{measurement.sample.Code}, badanie: #{test_name_for(measurement)}"
  end

  def test_name_for(measurement)
    Toxo::Constants::PROJECT_NAMES[measurement.ProjectId] || measurement.ProjectId
  end
end
