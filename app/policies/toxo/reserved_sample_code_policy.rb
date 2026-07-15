class Toxo::ReservedSampleCodePolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(InstitutionId: user.institution_id)
    end
  end
end
