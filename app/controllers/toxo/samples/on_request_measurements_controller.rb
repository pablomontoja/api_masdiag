class Toxo::Samples::OnRequestMeasurementsController < Toxo::SamplesController
  # POST /toxo/samples/on_request_measurements
  def create
    @sample = policy_scope(Toxo::Sample, policy_scope_class: Toxo::SamplePolicy::Scope)
                .find(params[:sample_id])
    authorize @sample, :create_on_request_measurement?, policy_class: Toxo::SamplePolicy

    if @sample.measurements.exists?(ProjectId: 42)
      return render json: { errors: { base: [ "Badanie na zlecenie już istnieje dla tej próbki" ] } },
                    status: :unprocessable_entity
    end

    note = params[:note].to_s.strip
    if note.blank?
      return render json: { errors: { note: [ "nie może być puste" ] } }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @sample.update_column(:Comment, append_comment(@sample.Comment, note))
      Measurement.create!(
        SampleId:     @sample.Id,
        ProjectId:    42,
        Status:       1,
        IsRepeat:     false,
        MaterialType: @sample.read_attribute(:MaterialType)
      )
    end

    render json: serialize_sample(@sample.reload), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.as_json, error_full_messages: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

  private

  def append_comment(existing, note)
    timestamp = Time.zone.now.strftime("%d.%m.%Y %H:%M")
    entry = "[#{timestamp}, #{current_contractor.fullname}] #{note}"
    existing.present? ? "#{existing}\n#{entry}" : entry
  end
end
