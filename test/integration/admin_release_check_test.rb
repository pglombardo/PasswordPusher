# frozen_string_literal: true

require "test_helper"

class AdminReleaseCheckTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:mr_admin)
    @user = users(:luca)
    @original_check_for_updates = Settings.check_for_updates
    Settings.check_for_updates = true
    Rails.cache.clear
  end

  teardown do
    Settings.check_for_updates = @original_check_for_updates
    Settings.reload!
  end

  test "banner is not shown to non-admin users" do
    cache_update

    sign_in @user
    get admin_root_path
    assert_response :not_found
    assert_select "#release-check-banner", count: 0

    get root_path
    assert_response :success
    assert_select "#release-check-banner", count: 0
  end

  test "banner is not shown on non-admin pages even for admins" do
    cache_update
    sign_in @admin

    get root_path
    assert_response :success
    assert_select "#release-check-banner", count: 0
  end

  test "admin dashboard shows an update banner and release card" do
    cache_update
    sign_in @admin

    get admin_root_path
    assert_response :success
    assert_select "#release-check-banner.alert-info"
    assert_select "#release-check-banner", text: /Password Pusher v99.0.0 is available/
    assert_select "#release-check-banner a", text: "View release notes"
    assert_select "#release-check-banner", text: /Dismiss/
    assert_select "#release-check-card", text: /Newer releases/
    assert_select "#release-check-card", text: /v99.0.0/
    assert_select "#release-check-card form[action=?]", admin_release_check_path
  end

  test "dismissed normal releases hide the banner but keep the dashboard card" do
    cache_update
    sign_in @admin

    post dismiss_admin_release_check_path, params: {version: "99.0.0"}
    follow_redirect!

    assert_response :success
    assert_select "#release-check-banner", count: 0
    assert_select "#release-check-card", text: /Password Pusher v99.0.0 is available/
  end

  test "security updates use danger styling and cannot be dismissed" do
    cache_update(security: true)
    sign_in @admin

    get admin_root_path
    assert_response :success
    assert_select "#release-check-banner.alert-danger"
    assert_select "#release-check-banner", text: /Dismiss/, count: 0
    assert_select "#release-check-card .badge", text: "Security"

    post dismiss_admin_release_check_path, params: {version: "99.0.0"}
    follow_redirect!

    assert_select "#release-check-banner.alert-danger"
    assert_select "#release-check-banner", text: /Dismiss/, count: 0
  end

  test "no banner when the cached latest matches the running version" do
    cache_update(latest: Version.current.to_s, current: Version.current.to_s, newer: [])
    sign_in @admin

    get admin_root_path
    assert_response :success
    assert_select "#release-check-banner", count: 0
    assert_select "#release-check-card", text: /You're running the latest version/
  end

  test "disabled setting shows a muted note and hides the banner and check button" do
    cache_update
    Settings.check_for_updates = false
    sign_in @admin

    get admin_root_path
    assert_response :success
    assert_select "#release-check-banner", count: 0
    assert_select "#release-check-card", text: /Update checks are disabled for this instance/
    assert_select "#release-check-card", text: /Check now/, count: 0
  end

  test "check now refreshes the cache synchronously" do
    sign_in @admin
    payload = {
      "schema" => 1,
      "product" => "oss",
      "generated_at" => "2026-11-27T00:00:00Z",
      "latest" => "99.0.0",
      "stable" => "99.0.0",
      "releases" => [release_hash("99.0.0")]
    }.to_json

    ReleaseCheck.stub :http_get_body, payload do
      post admin_release_check_path
    end
    follow_redirect!

    assert_response :success
    assert_equal "Checked for updates.", flash[:notice]
    assert_select "#release-check-banner", text: /v99.0.0/
  end

  test "check now does nothing when disabled" do
    Settings.check_for_updates = false
    sign_in @admin

    ReleaseCheck.stub :http_get_body, -> { flunk "HTTP should not be called when disabled" } do
      post admin_release_check_path
    end
    follow_redirect!

    assert_response :success
    assert_nil flash[:notice]
  end

  private

  def cache_update(latest: "99.0.0", current: Version.current.to_s, security: false, newer: nil)
    releases = newer || [release_hash(latest, security: security)]
    Rails.cache.write(
      ReleaseCheck::CACHE_KEY,
      {
        "latest" => latest,
        "current" => current,
        "newer_releases" => releases,
        "security_available" => security,
        "checked_at" => Time.current.iso8601,
        "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v#{latest}"
      },
      expires_in: 2.days
    )
  end

  def release_hash(version, security: false)
    {
      "version" => version,
      "date" => "2026-11-26",
      "security" => security,
      "severity" => security ? "high" : nil,
      "title" => "Release #{version}",
      "summary" => "Summary for #{version}",
      "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v#{version}"
    }
  end
end
