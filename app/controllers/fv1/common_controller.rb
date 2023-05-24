class Fv1::CommonController < V1::CommonController
  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/EdaWOY7NPeVOp78XtxPant4BJzk-6fINnz7cDU6sRKT-Hg?e=41LKmZ"}
  end
end
