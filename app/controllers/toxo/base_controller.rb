class Toxo::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_by_token!
  around_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def set_locale(&action)
    I18n.with_locale(current_contractor.locale.to_sym, &action)
  end

  def authenticate_by_token!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    return render_unauthorized unless token.present?

    @current_session = Session.includes(:contractor).find_by(token: token)
    render_unauthorized unless @current_session
  end

  def current_contractor
    @current_session.contractor
  end

  alias_method :pundit_user, :current_contractor

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
