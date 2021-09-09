ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/rails'

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...
end

# Debugging helper method
#
def pry!
  # Only valid for development or test environments
  # env = ENV['RACK_ENV'] || ENV['RAILS_ENV']
  # return unless %w(development, test).include? env
  require 'pry-byebug'

  if defined?(PryByebug)
    Pry.commands.alias_command 'c', 'continue'
    Pry.commands.alias_command 's', 'step'
    Pry.commands.alias_command 'n', 'next'
    Pry.commands.alias_command 'f', 'finish'

    Pry::Commands.command(/^$/, 'repeat last command') do
      _pry_.run_command Pry.history.to_a.last
    end
  end

  binding.pry
rescue LoadError
  puts("No debugger in bundle.  Couldn't load pry-byebug.")
end
