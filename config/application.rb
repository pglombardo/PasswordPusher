require_relative 'boot'

require 'rails'
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PasswordPusher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    # Enable the asset pipeline
    config.assets.enabled = true
    config.action_dispatch.default_headers.store('Report-To', '{"group":"default","max_age":31536000,"endpoints":[{"url":"https://d44c6675f6f03f85482859e657572968.report-uri.com/a/t/g"}],"include_subdomains":true}')
    config.action_dispatch.default_headers.store('NEL', '{"report_to":"default","max_age":31536000,"include_subdomains":true, "success_fraction": 1.0,"failure_fraction": 1.0}')
   

     # Version of your assets, change this if you want to expire all your assets

    

  end
end
