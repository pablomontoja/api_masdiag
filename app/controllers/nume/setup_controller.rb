class Nume::SetupController < ApplicationController
  include NumeCheck

  # POST  {data: {url: "https://fdsafd.dfsafda.pl"}}
  def set_result_post_endpoint_url
    Current.api_account.result_post_endpoint=(setup_params[:url])
    render json: { current_result_post_endpoint_url: Current.api_account.result_post_endpoint }, status: :ok
  end

  private

  def setup_params
    params.require(:data).permit(:url)
  end
end
