# frozen_string_literal: true

require "test_helper"

class SessionStoreTest < ActiveSupport::TestCase
  def setup
    # Store the original setting to restore it later
    @original_secure_cookies = Settings.secure_cookies
  end

  def teardown
    # Restore the original setting
    Settings.secure_cookies = @original_secure_cookies
    # Reload the initializer to restore the original configuration
    load Rails.root.join("config/initializers/session_store.rb")
  end

  test "session store uses secure options when secure_cookies is true" do
    # Set secure_cookies to true
    Settings.secure_cookies = true

    # Reload the initializer to apply the new setting
    load Rails.root.join("config/initializers/session_store.rb")

    # Get the session options from the application config
    session_options = PasswordPusher::Application.config.session_options

    # Assert that secure options are set correctly
    assert_equal true, session_options[:secure]
    assert_equal true, session_options[:httponly]
    assert_equal :strict, session_options[:same_site]
    assert_equal "_PasswordPusher_session", session_options[:key]
  end

  test "session store uses default options when secure_cookies is false" do
    # Set secure_cookies to false
    Settings.secure_cookies = false

    # Reload the initializer to apply the new setting
    load Rails.root.join("config/initializers/session_store.rb")

    # Get the session options from the application config
    session_options = PasswordPusher::Application.config.session_options

    # Assert that secure options are not set
    assert_nil session_options[:secure]
    assert_nil session_options[:httponly]
    assert_nil session_options[:same_site]
    assert_equal "_PasswordPusher_session", session_options[:key]
  end
end
