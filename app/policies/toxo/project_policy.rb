class Toxo::ProjectPolicy < ApplicationPolicy
  def index? = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(Id: Toxo::Constants::TOXO_PROJECT_IDS, is_active: true)
    end
  end
end
