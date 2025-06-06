# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require File.expand_path("../config/environment", __dir__)
require "rails/test_help"
require "minitest/rails"
require "i18n/tasks"

# Rubocop forces assert_not to be used instead of refute
# This adds assert_not to Minitest::Test
Minitest::Test.include(ActiveSupport::Testing::Assertions)

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

# Unset all PWP__ environment variables before tests
# This is to ensure that the test environment is not affected by the PWP__ environment variables
# that may be set in .env files, local development, or other environments.
ENV.keys.each do |key|
  ENV.delete(key) if key.start_with?("PWP__")
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
