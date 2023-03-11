module ApiHelpers
  def json
    JSON.parse(response.body)
  end

  def http_auth_header
    {"Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("username","password")}
  end
end
