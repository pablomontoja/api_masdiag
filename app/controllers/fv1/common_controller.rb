class Fv1::CommonController < V1::CommonController
  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/EazOUOwT-79Eu6-tJOCVGKYBK4jJqZ5xaOfYVV26srTjcg?e=fLoUkb"}
  end
end
