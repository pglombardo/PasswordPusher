require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  if Settings.throttling
    config.middleware.use Rack::Throttle::Daily,    max: Settings.throttling.daily
    config.middleware.use Rack::Throttle::Hourly,   max: Settings.throttling.hourly
    config.middleware.use Rack::Throttle::Minute,   max: Settings.throttling.minute
    config.middleware.use Rack::Throttle::Second,   max: Settings.throttling.second
  end

  config.assets.css_compressor = :sass
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.active_storage.service = Settings.files.storage

  config.force_ssl = ENV.key?('FORCE_SSL') ? true : false

  config.logger = Logger.new(STDOUT) if Settings.log_to_stdout
  config.log_level = Settings.log_level ? Settings.log_level.downcase.to_sym : 'error'
  config.log_tags = [ :request_id ]

  if Settings.mail
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

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present? || Settings.log_to_stdout
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
end
