Sentry.init do |config|
  config.dsn = 'https://87fb07837baa42bab8e7013323b4b706@glitchtip.masdiag.pl/3'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.rails.register_error_subscriber = true
  config.send_default_pii = true
  config.traces_sample_rate = 1.0 # 0 no errors, 1 all errors
  config.include_local_variables = true
  config.enabled_environments = %w[production]
end