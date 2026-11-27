# frozen_string_literal: true

require "application_system_test_case"
require "fileutils"

class ApiTokenPageTest < ApplicationSystemTestCase
  ARTIFACTS = Pathname.new("/opt/cursor/artifacts")

  setup do
    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  test "legacy, revealed, and masked token page states" do
    visit token_user_registration_path
    assert_text "Your existing API token still works, but it cannot be displayed"
    assert_selector "#authentication_token_hint", text: "••••7890"
    assert_no_selector "#authentication_token"
    save_token_screenshot("api-token-legacy")

    click_button "Regenerate Token"
    click_button "Delete & Regenerate"

    assert_text "Copy this token now. It will not be shown again."
    assert_selector "#authentication_token"
    token = find("#authentication_token").text.strip
    assert_operator token.length, :>, 4
    find("#authentication_token").click
    assert_selector "#authentication_token[data-spoiler-state='revealed']"
    # spoiler-alert animates filter over 250ms
    sleep 0.5
    save_token_screenshot("api-token-revealed-once")

    visit token_user_registration_path
    assert_text "Only a hint of this token is stored"
    assert_selector "#authentication_token_hint"
    assert_no_selector "#authentication_token"
    assert_no_text token
    assert_no_selector "#legacy-token-notice"
    save_token_screenshot("api-token-masked")
  end

  private

  def save_token_screenshot(name)
    path = Rails.root.join("tmp", "#{name}.png")
    page.save_screenshot(path) # rubocop:disable Lint/Debugger
    if ARTIFACTS.directory?
      FileUtils.mkdir_p(ARTIFACTS)
      FileUtils.cp(path, ARTIFACTS.join("#{name}.png"))
    end
  end
end
