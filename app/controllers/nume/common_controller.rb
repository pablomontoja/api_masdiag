class Nume::CommonController < Fv1::CommonController
  include NumeCheck

  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/ERkytYDpZbFAnSZJhlzhTwwBQyht1mquqH_4tjbpoOZV2g?e=Zd6wU3"}
  end
end
