class Nume::CommonController < Fv1::CommonController
  include NumeCheck

  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/ERHqtmGPJhpCraGenYpgt-8B903UjFnqn-JFYx4r6CDZRA?e=ofOCge"}
  end
end
