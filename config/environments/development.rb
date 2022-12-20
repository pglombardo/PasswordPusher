require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = Settings.files.storage

  if Settings.mail
    config.action_mailer.raise_delivery_errors = Settings.mail.raise_delivery_errors

    config.action_mailer.perform_caching = false

    config.action_mailer.default_url_options = { host: '127.0.0.1:5100', protocol: 'https' }

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

    config.action_mailer.smtp_settings[:domain] = Settings.mail.smtp_domain
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.perform_caching = false

    if Settings.mail.smtp_openssl_verify_mode
      config.action_mailer.smtp_settings[:openssl_verify_mode] = Settings.mail.smtp_openssl_verify_mode.to_sym
    end

    config.action_mailer.smtp_settings[:enable_starttls] = Settings.mail.smtp_enable_starttls
  end

  config.logger = Logger.new(STDOUT) if Settings.log_to_stdout
  config.log_level = :debug

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
