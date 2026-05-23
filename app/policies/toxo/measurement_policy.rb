class Toxo::MeasurementPolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      base = scope.where(ProjectId: Toxo::Constants::TOXO_PROJECT_IDS)
                  .joins(sample: :patient)

      if user.is_super_contractor?
        base.where(Patients: { ContractorId: user.institution.contractors.select(:Id) })
      else
        base.where(Patients: { ContractorId: user.Id })
      end
    end
  end
end
