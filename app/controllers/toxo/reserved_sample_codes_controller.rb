class Toxo::ReservedSampleCodesController < Toxo::BaseController
  before_action :set_rsc, only: :show

  # GET /toxo/reserved_sample_codes
  def index
    @rscs = policy_scope(ReservedSampleCode, policy_scope_class: Toxo::ReservedSampleCodePolicy::Scope).includes(:projects)
    render json: @rscs.map { |rsc| serialize_rsc(rsc) }
  end

  # GET /toxo/reserved_sample_codes/:id
  def show
    authorize @rsc, policy_class: Toxo::ReservedSampleCodePolicy
    render json: serialize_rsc(@rsc)
  end

  private

  def set_rsc
    @rsc = policy_scope(ReservedSampleCode, policy_scope_class: Toxo::ReservedSampleCodePolicy::Scope).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def serialize_rsc(rsc)
    {
      Id:            rsc.Id,
      Code:          rsc.Code,
      InstitutionId: rsc.InstitutionId,
      MaterialType:  rsc.MaterialType_before_type_cast,
      expiry_date:   rsc.expiry_date,
      lot:           rsc.lot,
      ref:           rsc.ref,
      projects_names: rsc.projects_names
    }
  end
end
