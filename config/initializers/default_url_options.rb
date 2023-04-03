hosts = {
  development: 'http://127.0.0.1:3000',
  staging: 'https://apisandbox.masdiag.pl',
  production: 'https://api.masdiag.pl',
  test: 'http://127.0.0.1:3000'
}.freeze

Rails.application.routes.default_url_options[:host] = hosts[Rails.env.to_sym]
