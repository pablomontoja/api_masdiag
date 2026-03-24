class Toxo::ProjectsController < Toxo::BaseController
  # GET /toxo/projects
  def index
    authorize Project, policy_class: Toxo::ProjectPolicy
    @projects = policy_scope(Project, policy_scope_class: Toxo::ProjectPolicy::Scope)
    render json: @projects.map { |p| serialize_project(p) }
  end

  private

  def serialize_project(project)
    {
      Id:                project.Id,
      Name:              project.Name,
      is_blocked_online: project.is_blocked_online,
      is_active:         project.is_active
    }
  end
end
