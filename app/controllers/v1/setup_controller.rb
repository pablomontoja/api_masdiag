class V1::SetupController < ApplicationController

  # POST  {data: {url: "https://fdsafd.dfsafda.pl"}}
  def result_post_endpoint
    aa = Current.api_account
    aa.result_post_endpoint = setup_params[:url]
    aa.result_post_endpoint_username = setup_params[:username]
    aa.result_post_endpoint_password = setup_params[:password]
    render json: { current_result_post_endpoint_url: aa.result_post_endpoint, 
                    current_result_post_endpoint_username: aa.result_post_endpoint_credentials&.username,
                    current_result_post_endpoint_password: password_shadow(aa.result_post_endpoint_credentials&.password) }, status: :ok
  end

  private

  def setup_params
    params.require(:data).permit(:url, :username, :password)
  end

  def password_shadow(password)
    return nil if password.nil?
    "*" * password.size
  end
end
