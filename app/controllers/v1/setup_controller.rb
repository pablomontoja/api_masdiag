class V1::SetupController < ApplicationController

  # POST  {data: {url: "https://fdsafd.dfsafda.pl"}}
  def set_result_post_endpoint_url
    Current.api_account.result_post_endpoint = setup_params[:url]
    Current.api_account.result_post_endpoint_username = setup_params[:username]
    Current.api_account.result_post_endpoint_password = setup_params[:password]
    render json: { current_result_post_endpoint_url: Current.api_account.result_post_endpoint, 
                    current_result_post_endpoint_username: Current.api_account.result_post_endpoint_credentials&.username,
                    current_result_post_endpoint_password: password_shadow(Current.api_account.result_post_endpoint_credentials&.password) }, status: :ok
  end

  private

  def setup_params
    params.require(:data).permit(:url, :username, :password)
  end

  def password_shadow(password)
    "*" * password.size
  end
end
