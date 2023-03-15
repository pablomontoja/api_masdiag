hosts = {
  development: { host: 'localhost:3000', protocol: "http" },
  staging: { host: 'apisandbox.masdiag.pl', protocol: "https" },
  production: { host: 'api.masdiag.pl', protocol: "https" }
}.freeze

Rails.application.routes.default_url_options[:host] = hosts[Rails.env.to_sym]
