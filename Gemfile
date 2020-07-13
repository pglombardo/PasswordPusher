source 'https://rubygems.org'

ruby ">=2.6.6"

gem 'rails', '~> 4.0'

gem 'rack-attack'

group :development, :test do
  gem "minitest"
  gem "minitest-reporters"
  gem "minitest-rails", "~> 2.0"
  gem 'pry'
  gem 'pry-byebug', :platforms => [ :mri_20, :mri_21, :mri_22 ]
end

gem 'web-console', '~> 2.0', :group => :development

gem 'protected_attributes'
gem 'json', '~> 2.0'
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


gem 'therubyracer'
gem 'ezcrypto', :git => 'https://github.com/pglombardo/ezcrypto.git'
gem 'modernizr-rails', :git => 'https://github.com/russfrisch/modernizr-rails.git'
gem "high_voltage"

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'sprockets', '~>3.0'

gem 'foreman'
gem 'unicorn'
gem 'jquery-rails'

group :production do
  gem 'pg', '~> 0.21'
end

group :private do
  gem "sqlite3", '< 1.4.0'
end
