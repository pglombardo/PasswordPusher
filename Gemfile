source 'https://rubygems.org'

ruby ">=2.3.8"

gem 'rails', '~> 6.0'

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  #gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'

  gem "minitest"
  gem "minitest-reporters"
  gem "minitest-rails"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-byebug', platforms: [:mri, :mingw, :x64_mingw]
end

gem 'rack-attack'
gem 'haml'
gem 'haml-rails'

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
#gem 'therubyracer'
#
gem 'ezcrypto', :git => 'https://github.com/pglombardo/ezcrypto.git'
gem 'modernizr-rails', :git => 'https://github.com/russfrisch/modernizr-rails.git'
gem "high_voltage"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'json', '~> 2.0' # Legacy carry-over
gem "webpacker"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'
#

gem "timers", '4.3.0'
gem 'sprockets', '~>4.0'
gem 'foreman'
gem 'unicorn'
gem 'jquery-rails'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem 'pg'
end

group :private do
  gem "sqlite3"
end
