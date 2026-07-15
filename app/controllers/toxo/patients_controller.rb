class Toxo::PatientsController < Toxo::BaseController
  before_action :set_patient, only: :show

  # GET /toxo/patients
  def index
    @patients = policy_scope(Patient, policy_scope_class: Toxo::PatientPolicy::Scope)
    render json: @patients.map { |p| serialize_patient(p) }
  end

  # GET /toxo/patients/:id
  def show
    authorize @patient, policy_class: Toxo::PatientPolicy
    render json: serialize_patient(@patient)
  end

  private

  def set_patient
    @patient = policy_scope(Patient, policy_scope_class: Toxo::PatientPolicy::Scope).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def serialize_patient(patient)
    {
      Id:           patient.Id,
      FirstName:    patient.FirstName,
      LastName:     patient.LastName,
      Pesel:        patient.Pesel,
      Gender:       patient.Gender,
      BirthDate:    patient.BirthDate,
      email:        patient.email,
      ContractorId: patient.ContractorId
    }
  end
end
