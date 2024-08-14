# rubocop:disable Rails/Output
# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "version"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PasswordPusher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.active_support.cache_format_version = 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    puts "Password Pusher Version: #{Version.current}"
  end

  # Grant system admin to a user by email
  #
  # @param email [String] the email of the user to grant system admin
  # @return [Boolean] true if the user was found and granted system admin, false otherwise
  def self.grant_system_admin!(email)
    user = User.find_by(email: email)
    if user
      user.update!(admin: true)
      Rails.logger.info "Granted system admin to #{email}!"
      true
    else
      Rails.logger.error "Could not find user with email: #{email}"
      false
    end
  end

  # Revoke system admin from a user by email
  #
  # @param email [String] the email of the user to revoke system admin
  # @return [Boolean] true if the user was found and revoked system admin, false otherwise
  def self.revoke_system_admin!(email)
    user = User.find_by(email: email)
    if user
      user.update!(admin: false)
      Rails.logger.info "Revoked system admin from #{email}!"
      true
    else
      Rails.logger.error "Could not find user with email: #{email}"
      false
    end
  end
end

# rubocop:enable Rails/Output
