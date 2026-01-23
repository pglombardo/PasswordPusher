# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # If you prefer to use Headless Chrome directly without a remote URL
  # driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # For debugging, sometimes it's helpful to see the browser
  # driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # Include Devise test helpers for system tests
  include Warden::Test::Helpers

  # Set up any specific system test configuration here
  setup do
    # Any setup needed for all system tests
  end

  teardown do
    # Any teardown needed for all system tests
  end
end
