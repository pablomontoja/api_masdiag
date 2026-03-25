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

    project_ids = Toxo::Constants.expand_project_ids(params[:project_ids] || [])
    patient = current_contractor.patient
    @sample = Toxo::Sample.new(sample_params)
    @sample.PatientId = patient.Id
    @sample.project_ids = Toxo::Constants.expand_project_ids(params[:project_ids] || [])

    # if project_ids.empty?
    #   @sample.valid?
    #   @sample.errors.add(:base, :no_tests_selected)
    # end

    # byebug

    wrong_registration = Toxo::Sample.where(IsWrongRegistration: true).find_by(Code: sample_params[:Code])

    ActiveRecord::Base.transaction do
      # byebug
      if wrong_registration
        @sample = wrong_registration
        # @sample.validate
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
        # @sample.save!
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
    end





    # ActiveRecord::Base.transaction do
    #   unless @sample.save
    #     raise ActiveRecord::Rollback
    #   end

    #   project_ids.each do |project_id|
    #     @sample.measurements.create!(
    #       ProjectId:    project_id,
    #       Status:       1,
    #       MaterialType: @sample.MaterialType_before_type_cast
    #     )
    #   end
    # end

    if @sample.errors.empty?
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
      :post_examination_procedure, :infectious_risk, :execution_mode, project_ids: []
    )
  end
end


def create
  authorize Sample
  @sample = Sample.new(sample_params)
  @sample.PatientId = current_contractor.patient.Id

  project_ids = params[:sample][:project_ids].to_a.reject(&:blank?).map(&:to_i)
  project_ids |= [39] if project_ids.include?(40)

  if project_ids.empty?
    @sample.errors.add(:base, :no_tests_selected)
    load_projects
    render :new, status: :unprocessable_entity and return
  end

  wrong_registration = Sample.where(IsWrongRegistration: true).find_by(Code: sample_params[:Code])

  ActiveRecord::Base.transaction do
    if wrong_registration
      wrong_registration.update!(
        sample_params.merge(
          RegistrationDate: Time.zone.now,
          IsWrongRegistration:     false,
          WasWrongRegistration:    true,
          WrongRegistrationStatus: 2,
          PatientId: current_contractor.patient.Id
        )
      )
      @sample = wrong_registration
      measurement_status = 1
    else
      @sample.save!
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
  end
end