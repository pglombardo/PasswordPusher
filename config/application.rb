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
   

     # Version of your assets, change this if you want to expire all your assets
	
	config.assets.paths << Rails.root.join("app", "assets", "fonts")
    

  end
end
