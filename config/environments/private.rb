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

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = Settings.mail.raise_delivery_errors

  config.action_mailer.default_url_options = {
    host: Settings.host_domain,
    protocol: Settings.host_protocol
  }

  config.action_mailer.smtp_settings = {
    address: Settings.mail.smtp_address,
    port: Settings.mail.smtp_port,
    user_name: Settings.mail.smtp_user_name,
    password: Settings.mail.smtp_password,
    authentication: Settings.mail.smtp_authentication,
    enable_starttls_auto: Settings.mail.smtp_starttls,
    open_timeout: Settings.mail.smtp_open_timeout,
    read_timeout: Settings.mail.smtp_read_timeout
  }
end
