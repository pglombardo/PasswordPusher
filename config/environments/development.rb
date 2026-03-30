# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

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

  config.action_mailer.delivery_method = :mailbin
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = {host: "127.0.0.1:5100"}

  config.logger = Logger.new($stdout) if Settings.log_to_stdout
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

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :solid_queue

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Propshaft uses Propshaft::Resolver::Static when public/assets/.manifest.json exists
  # (for example after running assets:precompile locally). That manifest only lists
  # precompiled app assets, so dev-only gems that ship CSS (e.g. mailbin) are missing
  # and stylesheet_link_tag raises MissingAssetError. Point at a path that does not
  # exist so the dynamic resolver serves engine assets in development.
  config.assets.manifest_path = Rails.root.join("tmp/.propshaft-development-manifest-placeholder")

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  config.hosts << "lvh.me"

  # The list of trusted proxies from which we will accept proxy related headers.
  # Covers common private / non-routable IPv4 ranges (RFC 1918, loopback, link-local, RFC 6598).
  config.action_dispatch.trusted_proxies = [
    /^::1$/, # IPv6 localhost
    /127\.\d{1,3}\.\d{1,3}\.\d{1,3}/, # IPv4 loopback (127.0.0.0/8)
    /10\.\d{1,3}\.\d{1,3}\.\d{1,3}/, # RFC 1918: 10.0.0.0/8
    /172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}/, # RFC 1918: 172.16.0.0/12 (e.g. Docker bridge)
    /192\.168\.\d{1,3}\.\d{1,3}/, # RFC 1918: 192.168.0.0/16
    /169\.254\.\d{1,3}\.\d{1,3}/, # IPv4 link-local (169.254.0.0/16)
    /100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.\d{1,3}\.\d{1,3}/ # RFC 6598: 100.64.0.0/10
  ]

  if Settings.trusted_proxies.present?
    trusted_proxies = Settings.trusted_proxies.split(",").map(&:strip)
    config.action_dispatch.trusted_proxies.concat(trusted_proxies)
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
