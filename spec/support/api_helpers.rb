module ApiHelpers
  def json
    JSON.parse(response.body)
  end

  def http_auth_header
    user = 'username'
    pw = 'password'
    # request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
    # get 'index', nil, 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password")
    {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)}
  end
end
