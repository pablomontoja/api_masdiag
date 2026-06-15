class Toxo::SamplesController < Toxo::BaseController
  include Toxo::Sortable

  SORTABLE_COLUMNS = {
    "code"            => "Samples.Code",
    "lot"             => "Samples.Lot",
    "dispatch_date"   => "Samples.dispatch_date",
    "acceptance_date" => "Samples.AcceptanceDate",
    "status"          => "Samples.SampleStatus"
  }.freeze

  before_action :set_sample, only: %i[show destroy]

  # GET /toxo/samples
  def index
    @samples = apply_sort(policy_scope(Toxo::Sample.all))
    render json: serialize_samples(@samples)
  end

  # GET /toxo/samples/:id
  def show
    authorize @sample
    render json: serialize_sample(@sample)
  end

  # DELETE /toxo/samples/:id
  def destroy
    authorize @sample

    ActiveRecord::Base.transaction do
      @sample.measurements.destroy_all
      @sample.destroy!
    end

    head :no_content
  end

  private

  def set_sample
    @sample = Toxo::Sample.joins(:measurements)
                          .where(measurements: { ProjectId: Toxo::Constants::TOXO_PROJECT_IDS })
                          .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def serialize_sample(sample)
    {
      Id:                         sample.Id,
      Code:                       sample.Code,
      MaterialType:               sample.MaterialType_before_type_cast,
      post_examination_procedure: sample.post_examination_procedure_before_type_cast,
      infectious_risk:            sample.infectious_risk_before_type_cast,
      execution_mode:             sample.execution_mode_before_type_cast,
      dispatch_date:              sample.dispatch_date,
      sample_collection_date:     sample.sample_collection_date,
      Lot:                        sample.Lot,
      Level:                      sample.Level,
      Comment:                    sample.Comment,
      AcceptanceDate:             sample.AcceptanceDate,
      RegistrationDate:           sample.RegistrationDate,
      IsWrongRegistration:        sample.IsWrongRegistration,
      WasWrongRegistration:       sample.WasWrongRegistration,
      SampleStatus:               sample.SampleStatus,
      SampleState:                sample.SampleState,
      measurements:               sample.measurements.map { |m|
        { Id: m.Id, ProjectId: m.ProjectId, Status: m.Status, SampleMaterialType: m.sample.MaterialType, IsRepeat: m.IsRepeat }
      }
    }
  end

  def serialize_samples(samples)
    samples.map { |s| serialize_sample(s) }
  end
end
