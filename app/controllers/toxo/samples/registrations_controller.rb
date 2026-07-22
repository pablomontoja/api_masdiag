class Toxo::Samples::RegistrationsController < Toxo::SamplesController
  # GET /toxo/samples/registrations/new
  def new
    authorize Toxo::Sample
    render json: {
      projects: Toxo::Constants::TOXO_PROJECT_IDS.map { |id| { id: id, name: Toxo::Constants::PROJECT_NAMES[id] } }
    }
  end

  # POST /toxo/samples/registrations
  def create
    authorize Toxo::Sample

    project_ids = Toxo::Constants.expand_project_ids(params[:project_ids] || [])
    patient = current_contractor.patient
    @sample = Toxo::Sample.new(sample_params)
    @sample.PatientId = patient.Id
    @sample.project_ids = Toxo::Constants.expand_project_ids(params[:project_ids] || [])

    wrong_registration = Toxo::Sample.where(IsWrongRegistration: true).find_by(Code: sample_params[:Code])

    ActiveRecord::Base.transaction do
      if wrong_registration
        @sample = wrong_registration
        @sample.assign_attributes(
          sample_params.merge(
            RegistrationDate: Time.zone.now,
            IsWrongRegistration:     false,
            WasWrongRegistration:    true,
            WrongRegistrationStatus: 2,
            PatientId: current_contractor.patient.Id
          )
        )
        raise ActiveRecord::Rollback unless @sample.save
        measurement_status = 1
      else
        raise ActiveRecord::Rollback unless @sample.save
        measurement_status = 7
      end

      project_ids.uniq.each do |project_id|
        Measurement.create!(
          SampleId:     @sample.Id,
          ProjectId:    project_id,
          Status:       measurement_status,
          IsRepeat:     false,
          MaterialType: @sample.read_attribute(:MaterialType)
        )
      end

      # project_ids.uniq.each do |project_id|
      #   if [39, 41].include?(project_id)
      #     [1, 2].each do |idx|
      #       is_repeat = idx == 2
      #       Measurement.create!(
      #         LabCode: "#{@sample.Code}_#{idx}",
      #         SampleId:     @sample.Id,
      #         ProjectId:    project_id,
      #         Status:       measurement_status,
      #         IsRepeat:     is_repeat,
      #         MaterialType: @sample.read_attribute(:MaterialType)
      #       )
      #     end
      #   else
      #     Measurement.create!(
      #       SampleId:     @sample.Id,
      #       ProjectId:    project_id,
      #       Status:       measurement_status,
      #       IsRepeat:     false,
      #       MaterialType: @sample.read_attribute(:MaterialType)
      #     )
      #   end
      # end

    end

    if @sample.errors.empty?
      render json: serialize_sample(@sample), status: :created
    else
      render json: { errors: @sample.errors.as_json, error_full_messages: @sample.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def sample_params
    p = params.permit(
      :Code, :dispatch_date, :sample_collection_date, :MaterialType,
      :Lot, :Level, :Comment,
      :post_examination_procedure, :infectious_risk, :execution_mode, :SampleStatus, project_ids: []
    )
    %i[MaterialType post_examination_procedure infectious_risk execution_mode].each do |key|
      p[key] = p[key].to_i if p[key].present?
    end
    # Only the "hold order" status may be set by the client; any other value is dropped
    # so the frontend can never force a Sample into an arbitrary status at registration time.
    p.delete(:SampleStatus) unless p[:SampleStatus].to_i == 3
    p
  end
end
