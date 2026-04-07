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
  # Run tests in parallel with half of available processors
  parallelize(workers: [Etc.nprocessors / 2, 1].max)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...

  def assert_audit_log_created(push, kind)
    assert push.audit_logs.where(kind: kind).exists?,
      "Expected audit log of kind #{kind} for push #{push.url_token}"
  end

  # User confirmable is optional (see Settings.enable_user_account_emails). The users fixture
  # (luca, one, giuliana, mr_admin) already has confirmed_at set, so sign_in works without
  # calling confirm_user. Use confirm_user only when you create a user in a test and need them
  # confirmed. For an unconfirmed user, set confirmed_at (and confirmation_token if needed) to nil.
  def confirm_user(user)
    user.confirm if user.respond_to?(:confirm)
  end

  # Assert user is "confirmed": either confirmable is disabled or the user is confirmed.
  def assert_user_confirmed(user)
    assert !user.respond_to?(:confirmed?) || user.confirmed?, "Expected user to be confirmed"
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end

ActiveSupport::Testing::Parallelization.after_fork_hooks << lambda { |worker_number|
  ENV["TEST_WORKER_NUMBER"] = worker_number.to_s
}
