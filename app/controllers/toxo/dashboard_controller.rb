class Toxo::DashboardController < Toxo::BaseController
  # GET /toxo/dashboard
  def index
    stats = Toxo::DashboardStatsQuery.new(user: current_contractor, window: params[:window]).call
    render json: stats
  end
end
