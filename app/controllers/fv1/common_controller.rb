class Fv1::CommonController < V1::CommonController
  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: V1::Common::FV1_CURRENT_DOCUMENTATION_URL}
  end
end
