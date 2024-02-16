# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require File.expand_path("../config/environment", __dir__)
require "rails/test_help"
require "minitest/rails"

# Rubocop forces assert_not to be used instead of refute
# This adds assert_not to Minitest::Test
Minitest::Test.include(ActiveSupport::Testing::Assertions)

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
