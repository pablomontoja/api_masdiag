class Nume::CommonController < Fv1::CommonController
  include NumeCheck

  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: V1::Common::NUME_CURRENT_DOCUMENTATION_URL}
  end
end
