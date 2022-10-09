PasswordPusher::Application.configure do
  config.cache_classes = false
  config.action_controller.perform_caching = false
  config.serve_static_files = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = true
  config.assets.digest = true
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.eager_load = false
  config.force_ssl = ENV.key?('FORCE_SSL') ? true : false

  config.logger = Logger.new(STDOUT) if Settings.log_to_stdout
  config.log_level = Settings.log_level.downcase.to_sym

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = Settings.mail.raise_delivery_errors

  config.action_mailer.default_url_options = {
    host: Settings.host_domain,
    protocol: Settings.host_protocol
  }

  config.middleware.use Rack::Throttle::Daily,    max: Settings.throttling.daily
  config.middleware.use Rack::Throttle::Hourly,   max: Settings.throttling.hourly
  config.middleware.use Rack::Throttle::Minute,   max: Settings.throttling.minute
  config.middleware.use Rack::Throttle::Second,   max: Settings.throttling.second

  config.action_mailer.smtp_settings = {
    address: Settings.mail.smtp_address,
    port: Settings.mail.smtp_port,
    user_name: Settings.mail.smtp_user_name,
    password: Settings.mail.smtp_password,
    authentication: Settings.mail.smtp_authentication,
    enable_starttls_auto: Settings.mail.smtp_enable_starttls_auto,
    open_timeout: Settings.mail.smtp_open_timeout,
    read_timeout: Settings.mail.smtp_read_timeout
  }

  if Settings.mail.smtp_domain
    config.action_mailer.smtp_settings[:domain] = Settings.mail.smtp_domain
  end

  if Settings.mail.smtp_openssl_verify_mode
    config.action_mailer.smtp_settings[:openssl_verify_mode] = Settings.mail.smtp_openssl_verify_mode.to_sym
  end

  if Settings.mail.smtp_enable_starttls
    config.action_mailer.smtp_settings[:enable_starttls] = Settings.mail.smtp_enable_starttls
  end
end
