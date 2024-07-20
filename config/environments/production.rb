# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable static file serving from the `/public` folder (turn off if using NGINX/Apache for it).
  # config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  config.assets.css_compressor = :sass
  config.assets.js_compressor = :terser

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = Settings.files.storage

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.key?("FORCE_SSL")

  # Logging
  config.logger = if ENV["RAILS_LOG_TO_STDOUT"].present? || Settings.log_to_stdout
    # Log to STDOUT by default
    ActiveSupport::Logger.new($stdout)
      .tap { |logger| logger.formatter = Logger::Formatter.new }
      .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  else
    ActiveSupport::TaggedLogging.new(Logger.new("log/production.log"))
      .tap { |logger| logger.formatter = ::Logger::Formatter.new }
      .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  end

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  # Obey settings.yml
  config.log_level = Settings.log_level

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "password_pusher_production"

  config.action_mailer.perform_caching = true

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.active_record.sqlite3_production_warning = false

  if Settings.mail
    config.action_mailer.perform_caching = false

    config.action_mailer.raise_delivery_errors = Settings.mail.raise_delivery_errors

    config.action_mailer.default_url_options = {
      host: Settings.host_domain,
      protocol: Settings.host_protocol
    }

    config.action_mailer.smtp_settings = {
      address: Settings.mail.smtp_address,
      port: Settings.mail.smtp_port
    }

    config.action_mailer.smtp_settings[:domain] = Settings.mail.smtp_domain if Settings.mail.smtp_domain
    config.action_mailer.smtp_settings[:open_timeout] = Settings.mail.smtp_open_timeout if Settings.mail.smtp_open_timeout
    config.action_mailer.smtp_settings[:read_timeout] = Settings.mail.smtp_read_timeout if Settings.mail.smtp_read_timeout

    if !Settings.mail.smtp_authentication.nil?
      config.action_mailer.smtp_settings[:authentication] = Settings.mail.smtp_authentication
    end

    if !Settings.mail.smtp_user_name.nil?
      config.action_mailer.smtp_settings[:user_name] = Settings.mail.smtp_user_name
    end

    if !Settings.mail.smtp_password.nil?
      config.action_mailer.smtp_settings[:password] = Settings.mail.smtp_password
    end

    if !Settings.mail.smtp_openssl_verify_mode.nil?
      config.action_mailer.smtp_settings[:openssl_verify_mode] = Settings.mail.smtp_openssl_verify_mode.to_sym
    end

    if !Settings.mail.smtp_enable_starttls_auto.nil?
      config.action_mailer.smtp_settings[:enable_starttls_auto] = Settings.mail.smtp_enable_starttls_auto
    end

    if !Settings.mail.smtp_enable_starttls.nil?
      config.action_mailer.smtp_settings[:enable_starttls] = Settings.mail.smtp_enable_starttls
    end
  end

  # If a user sets the allowed_hosts setting, we need to add the domain(s) to the list of allowed hosts
  if Settings.allowed_hosts.present?
    if Settings.allowed_hosts.is_a?(Array)
      config.hosts.concat(Settings.allowed_hosts)
    elsif Settings.allowed_hosts.is_a?(String)
      config.hosts.concat Settings.allowed_hosts.split
    else
      raise "Settings.allowed_hosts (PWP__ALLOWED_HOSTS): Allowed hosts must be an array or string"
    end
  end
end
