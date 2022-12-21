source 'https://rubygems.org'.freeze

ruby ENV['CUSTOM_RUBY_VERSION'] || '>=2.7.0'

gem 'rails', '~> 7.0.4'

group :development do
  gem 'debase', '0.2.5.beta2'
  gem 'listen'

  # Visual Studio Additions
  gem 'rubocop'
  gem 'ruby-debug-ide'

  # Access an interactive console on exception pages or by
  # calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.2.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.37.1', '< 4.0'
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'minitest-rails', '>= 6.1.0'
  gem 'selenium-webdriver', '4.7.1'
  gem 'webdrivers', '~> 5.0', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-byebug', platforms: [:mri, :mingw, :x64_mingw]
end

gem 'rack-cors'
gem 'rack-attack'

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
gem 'lockbox'
gem 'high_voltage'
gem 'kramdown', require: false

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0', '>= 6.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0', '>= 5.0.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11', '>= 2.11.5'
gem 'json', '~> 2.0' # Legacy carry-over
gem 'webpacker', '>= 5.4.3'
gem 'will_paginate', '~> 3.3.0'
gem 'will_paginate-bootstrap-style'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'foreman'
gem 'jquery-rails', '>= 4.5.0'
gem 'puma'
gem 'oj'
gem 'devise', '>= 4.8.1'
gem 'config'
gem 'route_translator', '>= 13.0.0'
gem 'translation'
gem 'mail_form', '>= 1.9.0'
gem 'apipie-rails'
gem 'simple_token_authentication', '~> 1.18', '>= 1.18.0', git: "https://github.com/pglombardo/simple_token_authentication.git", branch: 'rails7-support'
gem 'lograge'
gem 'rollbar'

# For File Uploads
gem "aws-sdk-s3", require: false
gem "azure-storage-blob", "~> 2.0", require: false
gem "google-cloud-storage", "~> 1.11", require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem 'pg'
end

group :private do
  gem 'sqlite3'
end

group :production, :private do
  gem 'rack-timeout'
  gem 'rack-throttle'
end
