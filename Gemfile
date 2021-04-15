source 'http://rubygems.org'

ruby "2.6.3"

gem 'rails', '~> 5.2.3'

group :development, :test do
  gem 'pry', '~> 0.12.2'
  gem 'pry-byebug', '~> 3.7.0', :platforms => [ :mri_20, :mri_21, :mri_22 ]
end




gem 'json', '~>2.0'
gem 'slim-rails', '~> 3.2'
gem 'ezcrypto', :git => 'https://github.com/pglombardo/ezcrypto.git'
#gem 'modernizr-rails', :git => 'https://github.com/russfrisch/modernizr-rails.git'
gem "high_voltage", '~> 3.1'

gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 5.0'
gem 'uglifier', '~> 4.1'

gem 'foreman', '~> 0.85'
gem 'unicorn', '~> 5.5'
gem 'jquery-rails', '~> 4.3'
gem 'popper_js', '~> 1.14'
gem 'bootstrap', '~> 4.3'

gem 'listen', '~> 3.1'

group :production, :test  do
  gem 'pg', '~>0.21'
end


group :private do
  gem "sqlite3", '~> 1.4'
end

gem 'puma', '~> 3.12'
