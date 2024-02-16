# frozen_string_literal: true

if defined?(Rollbar)
  Rollbar.configure do |config|
    # Without configuration, Rollbar is enabled in all environments.
    # To disable in specific environments, set config.enabled=false.

    config.access_token = ENV.fetch("ROLLBAR_ACCESS_TOKEN", nil)

    # Here we'll disable in 'test':
    config.enabled = false if Rails.env.test?

    # By default, Rollbar will try to call the `current_user` controller method
    # to fetch the logged-in user object, and then call that object's `id`
    # method to fetch this property. To customize:
    # config.person_method = "my_current_user"
    # config.person_id_method = "my_id"

    # Additionally, you may specify the following:
    # config.person_username_method = "username"
    # config.person_email_method = "email"

    # If you want to attach custom data to all exception and message reports,
    # provide a lambda like the following. It should return a hash.
    # config.custom_data_method = lambda { {:some_key => "some_value" } }

    # Add exception class names to the exception_level_filters hash to
    # change the level that exception is reported at. Note that if an exception
    # has already been reported and logged the level will need to be changed
    # via the rollbar interface.
    # Valid levels: 'critical', 'error', 'warning', 'info', 'debug', 'ignore'
    # 'ignore' will cause the exception to not be reported at all.
    # config.exception_level_filters.merge!('MyCriticalException' => 'critical')
    #
    # You can also specify a callable, which will be called with the exception instance.
    # config.exception_level_filters.merge!('MyCriticalException' => lambda { |e| 'critical' })
    config.exception_level_filters["ActiveRecord::RecordNotFound"] = "ignore"
    config.exception_level_filters["ActionController::RoutingError"] = "ignore"

    # Enable asynchronous reporting (uses girl_friday or Threading if girl_friday
    # is not installed)
    # config.use_async = true
    # Supply your own async handler:
    # config.async_handler = Proc.new { |payload|
    #  Thread.new { Rollbar.process_from_async_handler(payload) }
    # }

    # Enable asynchronous reporting (using sucker_punch)
    # config.use_sucker_punch

    # Enable delayed reporting (using Sidekiq)
    # config.use_sidekiq
    # You can supply custom Sidekiq options:
    # config.use_sidekiq 'queue' => 'default'

    # If your application runs behind a proxy server, you can set proxy parameters here.
    # If https_proxy is set in your environment, that will be used. Settings here have precedence.
    # The :host key is mandatory and must include the URL scheme (e.g. 'http://'), all other fields
    # are optional.
    #
    # config.proxy = {
    #   host: 'http://some.proxy.server',
    #   port: 80,
    #   user: 'username_if_auth_required',
    #   password: 'password_if_auth_required'
    # }

    # If you run your staging application instance in production environment then
    # you'll want to override the environment reported by `Rails.env` with an
    # environment variable like this: `ROLLBAR_ENV=staging`. This is a recommended
    # setup for Heroku. See:
    # https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment
    config.environment = ENV["ROLLBAR_ENV"].presence || Rails.env
  end
end
