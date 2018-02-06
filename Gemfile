source 'http://rubygems.org'

ruby ">=2.4.1"

gem 'rails', '~> 4.0'

gem 'rack-attack'

group :development, :test do
  gem 'pry'
  gem 'pry-byebug', :platforms => [ :mri_20, :mri_21, :mri_22 ]
end

gem 'web-console', '~> 2.0', :group => :development

gem 'protected_attributes'
gem 'json', '~> 2.0'
gem 'haml'
gem 'haml-rails'
gem 'therubyracer'
gem 'ezcrypto', :git => 'https://github.com/pglombardo/ezcrypto.git'
gem 'modernizr-rails', :git => 'https://github.com/russfrisch/modernizr-rails.git'
gem "high_voltage"

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'

gem 'foreman'
gem 'unicorn'
gem 'jquery-rails'

group :production do
  gem 'pg', '~> 0.21'
end

group :private do
  gem "sqlite3"
end
