class ApplicationController < ActionController::API
  include ::ActionController::HttpAuthentication::Basic::ControllerMethods
  include Response
  include ExceptionHandler

  before_action :authenticate

  private

  def authenticate
    authenticate_user || handle_bad_authentication
  end

  def authenticate_user
    authenticate_or_request_with_http_basic do |username, password|
      password == Rails.application.credentials.dig(:http_auth, :"#{username}")
    end
  end

  def handle_bad_authentication
    render json: { message: "Bad authentication credentials" }, status: :unauthorized
  end

end
