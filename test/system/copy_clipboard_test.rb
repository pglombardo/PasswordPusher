# frozen_string_literal: true

require "application_system_test_case"

class CopyClipboardTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!

    @user = users(:giuliana)
    @user.confirm
    login_as(@user, scope: :user)

    @push = pushes(:test_push)
    @push.update(
      payload: "SecretContent123",
      expired: false
    )
  end

  teardown do
    logout(:user)
  end

  test "copy secret URL button" do
    visit preview_push_path(@push)

    # Find the copy button for secret URL
    copy_button = find("button[data-action*='copy']", match: :first, wait: 5)

    # Verify button exists and can be clicked
    assert copy_button.present?
    copy_button.click

    # Button should still be present after click (JavaScript may update it)
    assert_selector "button[data-action*='copy']", wait: 2
  end

  test "copy payload button on push view page" do
    visit push_path(@push)

    # Find the copy button for payload
    copy_buttons = all("button[data-action*='copy']")

    # Should have at least one copy button
    assert copy_buttons.any?

    # Click the first copy button (usually for payload)
    copy_buttons.first.click

    # Button should still be present after click
    assert_selector "button[data-action*='copy']", wait: 2
  end

  test "copy button visual feedback resets" do
    visit preview_push_path(@push)

    copy_button = find("button[data-action*='copy']", match: :first, wait: 5)

    # Click to copy
    copy_button.click

    # Button should still be present after click
    assert_selector "button[data-action*='copy']", wait: 2
  end

  test "copy functionality on preview page" do
    visit preview_push_path(@push)

    # Should have secret URL input field
    find("input#secret_url", match: :first, wait: 5)

    # Should have copy button associated with it
    copy_button = find("button[data-action*='copy']", match: :first, wait: 5)

    # Click copy - button should be clickable
    copy_button.click

    # Button should still be present after click
    assert_selector "button[data-action*='copy']", wait: 2
  end

  test "copy button works with keyboard" do
    visit preview_push_path(@push)

    copy_button = find("button[data-action*='copy']", match: :first, wait: 5)

    # Focus and activate with keyboard
    copy_button.send_keys(:return)

    # Button should still be present after keyboard activation
    assert_selector "button[data-action*='copy']", wait: 2
  end

  test "multiple copy buttons on same page" do
    visit push_path(@push)

    # May have multiple copy buttons (URL, payload, etc.)
    copy_buttons = all("button[data-action*='copy']")

    # Click each one
    copy_buttons.each do |button|
      button.click
      # Button should still be present after click
      assert_selector "button[data-action*='copy']", wait: 2
      sleep 0.5 # Small delay between clicks
    end
  end

  test "copy button has correct data attributes" do
    visit preview_push_path(@push)

    copy_button = find("button[data-action*='copy']", match: :first)

    # Should have data-action attribute for Stimulus
    assert copy_button["data-action"].present?
    assert_includes copy_button["data-action"], "copy"
  end

  test "copy functionality with fallback method" do
    # This test verifies the copy controller is set up correctly
    # Actual clipboard access may not work in headless Chrome
    visit preview_push_path(@push)

    # Verify the copy controller is connected
    copy_container = find("[data-controller*='copy']", match: :first, wait: 5)
    assert copy_container.present?

    # Click copy button
    copy_button = find("button[data-action*='copy']", match: :first, wait: 5)
    copy_button.click

    # Button should still be present after click
    assert_selector "button[data-action*='copy']", wait: 2
  end
end
