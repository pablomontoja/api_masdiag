class Toxo::SamplesController < Toxo::BaseController
  include Toxo::Sortable
  include Toxo::Searchable
  include Toxo::Paginatable

  SORTABLE_COLUMNS = {
    "code"            => "Samples.Code",
    "lot"             => "Samples.Lot",
    "level"           => "Samples.Level",
    "dispatch_date"   => "Samples.dispatch_date",
    "acceptance_date" => "Samples.AcceptanceDate",
    "status"          => "Samples.SampleStatus"
  }.freeze

  SEARCHABLE_COLUMNS = %w[Samples.Code Samples.Lot].freeze

  before_action :set_sample, only: %i[show update destroy]

  # GET /toxo/samples
  def index
    scoped = apply_sort(apply_search(policy_scope(Toxo::Sample.all))).includes(:patient)
    @samples, meta = paginate(scoped)
    render json: { data: serialize_samples(@samples), meta: meta }
  end

  # GET /toxo/samples/:id
  def show
    authorize @sample
    render json: serialize_sample(@sample)
  end

  # PUT /toxo/samples/:id
  def update
    authorize @sample

    form = Toxo::SampleEditForm.new(sample: @sample, contractor: current_contractor, **sample_update_params)
    success = form.save

    if success
      render json: serialize_sample(@sample.reload).merge(saved_fields: form.saved_fields)
    else
      render json: serialize_sample(@sample.reload).merge(
        saved_fields:         form.saved_fields,
        errors:               form.errors.as_json,
        error_full_messages:  form.errors.full_messages
      ), status: :unprocessable_content
    end
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
    @sample = Toxo::Sample.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def sample_update_params
    params.permit(:Lot, :Level, :sample_collection_date, :dispatch_date, :note).to_h.symbolize_keys
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
      ContractorId:               sample.patient&.ContractorId,
      measurements:               sample.measurements.map { |m|
        { Id: m.Id, ProjectId: m.ProjectId, Status: m.Status, SampleMaterialType: m.sample.MaterialType, IsRepeat: m.IsRepeat }
      }
    }
  end

  def serialize_samples(samples)
    samples.map { |s| serialize_sample(s) }
  end
end
