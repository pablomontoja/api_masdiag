class AdminController < ActionController::API
	include ::ActionController::HttpAuthentication::Basic::ControllerMethods

	http_basic_authenticate_with(
		name: Rails.application.credentials.dig(:mission_control, :http_basic_auth_user),
		password: Rails.application.credentials.dig(:mission_control, :http_basic_auth_password)
	)
end