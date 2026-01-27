# frozen_string_literal: true

source "https://rubygems.org"

ruby ENV["CUSTOM_RUBY_VERSION"] || ">=3.4.3"

gem "rails", "~> 8.1.1"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "sass-embedded"
gem "cssbundling-rails"
gem "jsbundling-rails"

group :development do
  gem "listen"

  # Visual Studio Additions
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem install debase -v '0.2.9' -- --with-cflags=-Wno-error=incompatible-function-pointer-types
  # https://blog.arkency.com/how-to-get-burned-by-16-years-old-hack-in-2024/
  gem "debase"
  gem "ruby-debug-ide"
  gem "pry-rails"
  gem "web-console"

  # A fully configurable and extendable Git hook manager
  gem "overcommit", require: false

  gem "mailbin"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.37.1", "< 4.0"
  gem "minitest"
  gem "minitest-rails", ">= 6.1.0"
  gem "minitest-reporters"
  gem "selenium-webdriver", ">= 4.20.1"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "i18n-tasks", "~> 1.1.2", require: false
  gem "erb_lint", "~> 0.9.0", require: false
  gem "standard", ">= 1.35.1"
end

gem "rack-cors"
gem "high_voltage"
gem "kramdown", require: false
gem "lockbox"

gem "terser", "~> 1.2"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "bootstrap"
gem "json", "~> 2.18" # Legacy carry-over

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# https://github.com/Apipie/apipie-rails/pull/964
gem "apipie-rails", github: "Apipie/apipie-rails", branch: "copilot/fix-router-deprecation-warning"

gem "config"
gem "devise", "~> 5.0"
gem "foreman"
gem "lograge"
gem "mail_form", ">= 1.9.0"
gem "oj"
gem "puma"
gem "kaminari", "~> 1.2"
gem "invisible_captcha", "~> 2.3"

gem "devise-i18n"
gem "rails-i18n", "~> 8.1.0"
gem "translation"

# For File Uploads
gem "aws-sdk-s3", require: false
gem "azure-blob", "~> 0.8.0", require: false
gem "google-cloud-storage", "~> 1.58", require: false

# Database backends
gem "mysql2"
gem "pg"
gem "sqlite3", force_ruby_platform: true

group :production, :development do
  gem "rack-attack"
end

gem "rollbar"
gem "version", git: "https://github.com/pglombardo/version.git", branch: "master"
gem "madmin"
gem "rqrcode", "~> 3.2"
gem "turnout2024", require: "turnout"
gem "mission_control-jobs", "~> 1.1.0"
gem "overmind", "~> 2.5", group: :development

gem "dotenv", "~> 3.2"
