hosts = {
  development: { host: '127.0.0.1:3000', protocol: "http" },
  staging: { host: 'apisandbox.masdiag.pl', protocol: "https" },
  production: { host: 'api.masdiag.pl', protocol: "https" },
  test: { host: '127.0.0.1:3000', protocol: "http" }
}.freeze

Rails.application.routes.default_url_options[:host] = hosts[Rails.env.to_sym]
