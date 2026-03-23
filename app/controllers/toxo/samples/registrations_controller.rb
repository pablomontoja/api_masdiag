class Toxo::Samples::RegistrationsController < Toxo::SamplesController
  # GET /toxo/samples/registrations/new
  def new
    authorize Toxo::Sample
    render json: {
      projects: Toxo::Constants::TOXO_PROJECT_IDS.map { |id| { id: id, name: Toxo::PROJECT_NAMES[id] } }
    }
  end

  # POST /toxo/samples/registrations
  def create
    authorize Toxo::Sample

    project_ids = Toxo.expand_project_ids(params[:project_ids] || [])

    if project_ids.empty?
      return render json: { errors: { project_ids: ["must include at least one valid toxo project"] } },
                    status: :unprocessable_entity
    end

    patient = current_contractor.patient

    @sample = Toxo::Sample.new(sample_params)
    @sample.PatientId = patient.Id

    ActiveRecord::Base.transaction do
      unless @sample.save
        raise ActiveRecord::Rollback
      end

      project_ids.each do |project_id|
        @sample.measurements.create!(
          ProjectId:    project_id,
          Status:       1,
          MaterialType: @sample.MaterialType_before_type_cast
        )
      end
    end

    if @sample.persisted?
      render json: serialize_sample(@sample), status: :created
    else
      render json: { errors: @sample.errors.as_json }, status: :unprocessable_entity
    end
  end

  private

  def sample_params
    params.permit(
      :Code, :dispatch_date, :MaterialType,
      :Lot, :Level, :Comment,
      :post_examination_procedure, :infectious_risk, :execution_mode
    )
  end
end
