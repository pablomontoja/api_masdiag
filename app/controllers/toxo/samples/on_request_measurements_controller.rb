class Toxo::Samples::OnRequestMeasurementsController < Toxo::SamplesController
  # POST /toxo/samples/on_request_measurements
  def create
    @sample = policy_scope(Toxo::Sample, policy_scope_class: Toxo::SamplePolicy::Scope)
                .find(params[:sample_id])
    authorize @sample, :create_on_request_measurement?, policy_class: Toxo::SamplePolicy

    if @sample.measurements.exists?(ProjectId: 42)
      return render json: { errors: { base: [ "Badanie na zlecenie już istnieje dla tej próbki" ] } },
                    status: :unprocessable_content
    end

    note = params[:note].to_s.strip
    if note.blank?
      return render json: { errors: { note: [ "nie może być puste" ] } }, status: :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      @sample.append_comment(note, current_contractor)
      @measurement = Measurement.create!(
        SampleId:     @sample.Id,
        ProjectId:    42,
        Status:       1,
        IsRepeat:     false,
        MaterialType: @sample.read_attribute(:MaterialType)
      )
    end

    Toxo::SampleNotificationMailer.on_request_measurement(@measurement, current_contractor).deliver_later

    render json: serialize_sample(@sample.reload), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.as_json, error_full_messages: e.record.errors.full_messages },
           status: :unprocessable_content
  end
end
