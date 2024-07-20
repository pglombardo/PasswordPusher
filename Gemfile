# frozen_string_literal: true

source "https://rubygems.org"

ruby ENV["CUSTOM_RUBY_VERSION"] || ">=3.1.4"

gem "rails", "~> 7.1.3"

group :development do
  gem "listen"

  # Visual Studio Additions
  gem "ruby-debug-ide"

  gem "pry-rails"

  # Access an interactive console on exception pages or by
  # calling 'console' anywhere in the code.
  gem "web-console", ">= 4.2.0"

  gem "derailed_benchmarks"
  gem "stackprof"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.37.1", "< 4.0"
  gem "minitest"
  gem "minitest-rails", ">= 6.1.0"
  gem "minitest-reporters"
  gem "selenium-webdriver"
  gem "webdrivers", "~> 5.3", require: false
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem install debase -v '0.2.5.beta2' -- --with-cflags=-Wno-error=incompatible-function-pointer-types
  # https://blog.arkency.com/how-to-get-burned-by-16-years-old-hack-in-2024/
  gem "debase", ">= 0.2.5.beta2", platforms: %i[mri mingw x64_mingw]
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "erb_lint", "~> 0.5.0"
  gem "standardrb", "~> 1.0"
end

gem "rack-cors"

# OSX: ../src/utils.h:33:10: fatal error: 'climits' file not found
# From:
# # 1. Install v8 ourselves
# $ brew install v8-315
# # 2. Install libv8 using the v8 binary we just installed
# $ gem install libv8 -v '3.16.14.19' -- --with-system-v8
# # 3. Install therubyracer using the v8 binary we just installed
# $ gem install therubyracer -- --with-v8-dir=/usr/local/opt/v8@315
# # 4. Install the remaining dependencies
# $ bundle install
# gem 'therubyracer'
#
gem "high_voltage"
gem "kramdown", require: false
gem "lockbox"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0", ">= 6.0.0"
gem "terser", "~> 1.2"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "bootstrap", "5.2.3"
gem "json", "~> 2.7" # Legacy carry-over

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem "apipie-rails"
gem "config"
gem "devise", ">= 4.9.0"
gem "foreman"
gem "lograge"
gem "mail_form", ">= 1.9.0"
gem "oj"
gem "puma"
gem "rollbar"
gem "simple_token_authentication"
gem "kaminari", "~> 1.2"
gem "invisible_captcha", "~> 2.3"

gem "devise-i18n"
gem "i18n-tasks", "~> 1.0.14" # , group: :development
gem "rails-i18n", "~> 7.0.9"
gem "translation"

# For File Uploads
gem "aws-sdk-s3", require: false
gem "azure-storage-blob", "~> 2.0", require: false
gem "google-cloud-storage", "~> 1.52", require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Database backends
gem "mysql2"
gem "pg"
gem "sqlite3", force_ruby_platform: true

group :production do
  gem "rack-attack"
  gem "rack-timeout"
end

gem "version", git: "https://github.com/pglombardo/version.git", branch: "master"

gem "administrate", "~> 0.20.1"

gem "rqrcode", "~> 2.2"
