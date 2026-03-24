class Toxo::PatientPolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_super_contractor?
        scope.joins(:contractor)
             .where(Contractors: { institution_id: user.institution_id })
      else
        scope.where(ContractorId: user.Id)
      end
    end
  end
end
