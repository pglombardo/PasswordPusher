source 'https://rubygems.org'
# source 'https://repo.fury.io/pglombardo/'

gem 'rails', '~> 3.2'

group :development, :test do
  gem 'ruby-debug',   :platforms => [ :mri_18, :jruby ]
  gem 'debugger',     :platform  =>   :mri_19
  gem 'byebug',       :platforms => [ :mri_20, :mri_21, :mri_22 ]
  if RUBY_VERSION > '1.8.7'
    gem 'pry'
    gem 'pry-byebug', :platforms => [ :mri_20, :mri_21, :mri_22 ]
  else
    gem 'pry', '0.9.12.4'
  end

  gem 'silent-postgres'
  gem "nifty-generators"
end

gem 'json', '~> 2.0'
gem 'haml'
gem 'haml-rails'
gem 'therubyracer'
gem 'ezcrypto', :git => 'https://github.com/pglombardo/ezcrypto.git'
gem 'modernizr-rails', :git => 'https://github.com/russfrisch/modernizr-rails.git'
gem "high_voltage", '~> 2.1.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

gem 'foreman'
gem 'unicorn'
gem 'jquery-rails'
gem "devise"
gem "omniauth"
gem 'omniauth-openid'
gem 'omniauth-twitter'

group :production do
  gem 'pg'
end

group :private do
  gem "sqlite3"
end
