# frozen_string_literal: true

require "application_system_test_case"

class PushCreationWorkflowsTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_password_pushes = true
    Settings.enable_url_pushes = true
    Settings.enable_file_pushes = true
    Settings.enable_qr_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
  end

  # Password Push Creation
  test "password push creation workflow" do
    visit new_push_path(tab: "text")

    # Verify we're on the password form (check for tab or form field)
    assert_selector "textarea#push_payload", wait: 5
    assert_selector "a.nav-link.active", text: /password/i, wait: 5

    # Fill in the password
    fill_in "push_payload", with: "MySecretPassword123!"

    # Submit the form
    click_button "Push It!"

    # Should redirect to preview page
    # URL tokens use urlsafe_base64 which can include hyphens and underscores
    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  test "password push creation with custom expiration" do
    visit new_push_path(tab: "text")

    fill_in "push_payload", with: "TestPassword"

    # Set custom expiration values using the range inputs
    days_input = find("input[name='push[expire_after_days]']", wait: 5)
    days_input.set("3")

    views_input = find("input[name='push[expire_after_views]']", wait: 5)
    views_input.set("5")

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  test "password push creation with retrieval step enabled" do
    visit new_push_path(tab: "text")

    fill_in "push_payload", with: "TestPassword"
    check "push_retrieval_step"

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  test "password push creation with passphrase" do
    visit new_push_path(tab: "text")

    fill_in "push_payload", with: "TestPassword"
    fill_in "push_passphrase", with: "mypassphrase"

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  test "password push form validation" do
    visit new_push_path(tab: "text")

    # Try to submit without payload
    click_button "Push It!"

    # Should show validation error or stay on page
    # HTML5 validation may prevent submission, or Rails validation may show error
    sleep 1
    # Either we're still on the form page or we see an error
    assert(page.current_path.include?("new") || page.has_text?(/can't be blank|required/i, wait: 5))
  end

  # URL Push Creation
  test "url push creation workflow" do
    visit new_push_path(tab: "url")

    # Verify we're on the URL form
    assert_selector "input#push_payload", wait: 5
    assert_selector "a.nav-link.active", text: /url/i, wait: 5

    # Fill in the URL
    fill_in "push_payload", with: "https://example.com"

    # Submit the form
    click_button "Push It!"

    # Should redirect to preview page
    # URL tokens use urlsafe_base64 which can include hyphens and underscores
    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  test "url push creation with custom expiration" do
    visit new_push_path(tab: "url")

    fill_in "push_payload", with: "https://example.com"

    days_input = find("input[name='push[expire_after_days]']", wait: 5)
    days_input.set("2")

    views_input = find("input[name='push[expire_after_views]']", wait: 5)
    views_input.set("3")

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
  end

  test "url push form validation" do
    visit new_push_path(tab: "url")

    # Try to submit without URL
    click_button "Push It!"

    # Should show validation error or stay on page
    sleep 1
    assert(page.current_path.include?("new") || page.has_text?(/can't be blank|required/i, wait: 5))
  end

  # File Push Creation
  test "file push creation workflow" do
    visit new_push_path(tab: "files")

    # Verify we're on the file form
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    # Upload a file
    file_path = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    attach_file "push_files", file_path, make_visible: true

    # Wait for file to be attached (check for file name in page)
    assert_text "test-file.txt", wait: 10

    # Submit the form
    click_button "Push It!"

    # Should redirect to preview page
    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 10
    assert_text "Push Preview", wait: 5
  end

  test "file push creation with multiple files" do
    visit new_push_path(tab: "files")

    file_path1 = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    file_path2 = Rails.root.join("test", "fixtures", "files", "monkey.png")

    attach_file "push_files", [file_path1, file_path2], make_visible: true

    # Wait for files to be attached
    assert_text "test-file.txt", wait: 10
    assert_text "monkey.png", wait: 10

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 10
  end

  # QR Push Creation
  test "qr push creation workflow" do
    visit new_push_path(tab: "qr")

    # Verify we're on the QR form
    assert_selector "textarea#push_payload", wait: 5
    assert_selector "a.nav-link.active", text: /qr/i, wait: 5

    # Fill in the payload
    fill_in "push_payload", with: "QR Code Content"

    # Submit the form
    click_button "Push It!"

    # Should redirect to preview page
    # URL tokens use urlsafe_base64 which can include hyphens and underscores
    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end

  # Tab Switching
  test "tab switching between push types" do
    visit new_push_path(tab: "text")
    assert_selector "a.nav-link.active", text: /password/i, wait: 5
    assert_selector "textarea#push_payload", wait: 5

    visit new_push_path(tab: "url")
    assert_selector "a.nav-link.active", text: /url/i, wait: 5
    assert_selector "input#push_payload", wait: 5

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    visit new_push_path(tab: "qr")
    assert_selector "a.nav-link.active", text: /qr/i, wait: 5
    assert_selector "textarea#push_payload", wait: 5
  end

  test "authenticated user can add name and note" do
    visit new_push_path(tab: "text")

    fill_in "push_payload", with: "TestPassword"
    fill_in "push_name", with: "My Push Name"
    fill_in "push_note", with: "My reference note"

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
  end
end
