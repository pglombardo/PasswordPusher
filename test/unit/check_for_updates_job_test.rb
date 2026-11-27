# frozen_string_literal: true

require "test_helper"

class CheckForUpdatesJobTest < ActiveSupport::TestCase
  setup do
    @original_check_for_updates = Settings.check_for_updates
  end

  teardown do
    Settings.check_for_updates = @original_check_for_updates
    Settings.reload!
  end

  test "refreshes the release check when enabled" do
    Settings.check_for_updates = true
    called = false

    ReleaseCheck.stub :refresh, -> { called = true } do
      CheckForUpdatesJob.perform_now
    end

    assert called, "expected CheckForUpdatesJob to refresh the release check"
  end

  test "does nothing when update checks are disabled" do
    Settings.check_for_updates = false
    called = false

    ReleaseCheck.stub :refresh, -> { called = true } do
      CheckForUpdatesJob.perform_now
    end

    assert_not called, "expected CheckForUpdatesJob not to refresh when disabled"
  end
end
