class Toxo::SamplePolicy < ApplicationPolicy
  def index?   = true
  def show?    = owner_or_super?
  def new?     = user.can_add_samples?
  def create?  = user.can_add_samples?
  def destroy? = record.deletable? && owner?
  def create_on_request_measurement? = user.can_add_samples? && owner_or_super?

  class Scope < ApplicationPolicy::Scope
    def resolve
      base_ids = if user.is_super_contractor?
        scope.joins(patient: :contractor)
             .where(Contractors: { institution_id: user.institution_id })
             .where(Patients: { FirstName: "PACJENT", LastName: "TOXO" })
             .select(:Id)
      else
        toxo_patient = Patient.find_by(
          ContractorId: user.Id,
          FirstName:    "PACJENT",
          LastName:     "TOXO"
        )
        toxo_patient.nil? ? [] : scope.where(PatientId: toxo_patient.Id).select(:Id)
      end

      rscs = ReservedSampleCode.where(InstitutionId: user.institution_id)
                               .where("LENGTH(ReservedSampleCodes.Code) = 7")

      wrong_ids = scope.joins(:reserved_sample_code)
                       .where(reserved_sample_code_id: rscs.select(:Id))
                       .where(IsWrongRegistration: true)
                       .select(:Id)

      all_ids = base_ids.pluck(:Id) | wrong_ids.pluck(:Id)
      scope.where(Id: all_ids)
    end
  end

  def owner_or_super?
    owner? || user.is_super_contractor?
  end

  private

  def owner?
    record.patient.ContractorId == user.Id
  end
end
