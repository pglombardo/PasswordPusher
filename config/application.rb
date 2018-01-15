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
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    # Enable the asset pipeline
    config.assets.enabled = true

     # Version of your assets, change this if you want to expire all your assets
     config.assets.version = '1.3'
     config.before_configuration do
       env_file = File.join(Rails.root, 'config', 'local_env.yml')
       YAML.load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value
       end if File.exists?(env_file)
    end
    config.assets.initialize_on_precompile = false
    config.assets.precompile += ['fd-slider.css', 'fd-slider.js', 'modernizr.js', 'show.js','passwords.js']

  end
end
