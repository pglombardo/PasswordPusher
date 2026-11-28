# frozen_string_literal: true

require "test_helper"

class AdminHelperTest < ActionView::TestCase
  include AdminHelper

  # ActionView helper tests inherit Minitest's `_` matcher; gettext `_()` is
  # what production views use. Identity-translate so interpolation still works.
  def _(msgid)
    msgid
  end

  setup do
    @original_check_for_updates = Settings.check_for_updates
    Settings.check_for_updates = true
  end

  teardown do
    Settings.check_for_updates = @original_check_for_updates
    Settings.reload!
  end

  test "banner is visible when an update is available and not dismissed" do
    result = build_result(latest: "9.0.0")

    Version.stub :current, "1.0.0" do
      assert release_banner_visible?(result)
    end
  end

  test "banner is hidden when the dismiss cookie matches the target version" do
    result = build_result(latest: "2.17.2", channel: "stable")
    cookies[ReleaseCheck::DISMISS_COOKIE] = "2.17.2"

    Version.stub :current, "2.17.0" do
      assert_not release_banner_visible?(result)
    end
  end

  test "banner stays visible when the dismiss cookie is a different channel target" do
    result = build_result(latest: "2.17.2", channel: "stable")
    cookies[ReleaseCheck::DISMISS_COOKIE] = "2.17.5"

    Version.stub :current, "2.17.0" do
      assert release_banner_visible?(result)
    end
  end

  test "security updates stay visible even when dismissed" do
    result = build_result(
      latest: "2.17.2",
      channel: "stable",
      newer_releases: [{"version" => "2.17.2", "security" => true}],
      security_available: true
    )
    cookies[ReleaseCheck::DISMISS_COOKIE] = "2.17.2"

    Version.stub :current, "2.17.0" do
      assert release_banner_visible?(result)
    end
  end

  test "banner is hidden when no update is available" do
    result = build_result(latest: "2.17.2", channel: "stable")

    Version.stub :current, "2.17.2" do
      assert_not release_banner_visible?(result)
    end
  end

  test "banner is hidden when update checks are disabled" do
    Settings.check_for_updates = false
    result = build_result(latest: "9.0.0")

    Version.stub :current, "1.0.0" do
      assert_not release_banner_visible?(result)
    end
  end

  test "latest channel headline is unchanged" do
    result = build_result(latest: "9.0.0")

    Version.stub :current, "1.0.0" do
      assert_equal "Password Pusher v9.0.0 is available (you're running v1.0.0)",
        release_update_headline(result)
    end
  end

  test "stable channel headline mentions the stable channel" do
    result = build_result(latest: "2.17.2", channel: "stable")

    Version.stub :current, "2.17.0" do
      assert_equal "Password Pusher v2.17.2 is now available on the stable channel (you're running v2.17.0).",
        release_update_headline(result)
    end
  end

  test "up to date message follows the channel" do
    latest_result = build_result(latest: "2.18.0")
    stable_result = build_result(latest: "2.17.2", channel: "stable")

    assert_equal "You're running the latest version.", release_up_to_date_message(latest_result)
    assert_equal "You're running the current stable version.", release_up_to_date_message(stable_result)
  end

  private

  def build_result(latest:, channel: "latest", newer_releases: nil, security_available: false)
    ReleaseCheck::Result.new(
      latest: latest,
      current: "1.0.0",
      newer_releases: newer_releases || [{"version" => latest, "security" => security_available}],
      security_available: security_available,
      checked_at: Time.current.iso8601,
      notes_url: ReleaseCheck::DEFAULT_NOTES_URL,
      channel: channel
    )
  end
end
