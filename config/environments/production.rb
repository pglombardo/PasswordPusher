Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  config.middleware.use Rack::Throttle::Daily,    max: Settings.throttling.daily
  config.middleware.use Rack::Throttle::Hourly,   max: Settings.throttling.hourly
  config.middleware.use Rack::Throttle::Minute,   max: Settings.throttling.minute
  config.middleware.use Rack::Throttle::Second,   max: Settings.throttling.second

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.key?('FORCE_SSL') ? true : false

  config.logger = Logger.new(STDOUT) if Settings.log_to_stdout
  config.log_level = Settings.log_level.downcase.to_sym

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "password_pusher_production"

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

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
