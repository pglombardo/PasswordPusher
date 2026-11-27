# frozen_string_literal: true

require "application_system_test_case"

class AdminReleaseCheckSystemTest < ApplicationSystemTestCase
  setup do
    @original_check_for_updates = Settings.check_for_updates
    @original_release_channel = Settings.release_channel
    Settings.check_for_updates = true
    Settings.release_channel = "stable"
    Rails.cache.clear
  end

  teardown do
    Settings.check_for_updates = @original_check_for_updates
    Settings.release_channel = @original_release_channel
    Settings.reload!
  end

  test "stable channel banner mentions the stable channel and docker pull hint" do
    Rails.cache.write(
      ReleaseCheck::CACHE_KEY,
      {
        "latest" => "99.0.0",
        "current" => Version.current.to_s,
        "newer_releases" => [{
          "version" => "99.0.0",
          "date" => "2026-11-10",
          "security" => false,
          "title" => "v99.0.0: Stable channel target",
          "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v99.0.0"
        }],
        "security_available" => false,
        "checked_at" => Time.current.iso8601,
        "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v99.0.0",
        "channel" => "stable"
      },
      expires_in: 2.days
    )

    login_as(users(:mr_admin), scope: :user)
    visit admin_root_path

    assert_selector "#release-check-banner", text: /now available on the stable channel/
    assert_selector "#release-check-banner", text: /re-pull pglombardo\/pwpush:stable/
    assert_selector "#release-check-banner a", text: "View release notes"
    assert_selector "#release-check-card", text: /Update channel: stable/
    assert_selector "#release-check-card", text: /now available on the stable channel/
  end
end
