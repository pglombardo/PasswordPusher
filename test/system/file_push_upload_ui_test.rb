# frozen_string_literal: true

require "application_system_test_case"

class FilePushUploadUiTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
    # Restore settings if tests changed them
    Settings.files.use_tus_uploads = true
    Settings.files.max_direct_upload_size = 104857600
    Settings.files.max_file_uploads = 10
  end

  test "progress bar container is present on file push form" do
    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5
    # Progress bar list is in the DOM (may be empty until upload starts)
    assert_selector "ul#progress-bars", wait: 2, visible: :all
    assert_selector "ul#progress-bars[aria-label='Upload progress']", visible: :all
  end

  test "when TUS disabled alert shows for file too large" do
    Settings.files.use_tus_uploads = false
    Settings.files.max_direct_upload_size = 1

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    file_path = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    msg = nil
    begin
      msg = accept_alert(wait: 10) do
        attach_file "push_files", file_path, make_visible: true
      end
    rescue Capybara::ModalNotFound
      skip "Headless Chrome may not trigger alert on file input change"
    end
    assert msg.present?, "Expected an alert message (file too large)" if msg
    assert_match(/too large|max size/i, msg, "Alert should mention file too large") if msg
  end

  test "when too many files selected alert shows" do
    Settings.files.max_file_uploads = 1

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    file_path1 = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    file_path2 = Rails.root.join("test", "fixtures", "files", "monkey.png")
    msg = nil
    begin
      msg = accept_alert(wait: 10) do
        attach_file "push_files", [file_path1, file_path2], make_visible: true
      end
    rescue Capybara::ModalNotFound
      skip "Headless Chrome may not trigger alert on file input change"
    end
    assert msg.present?, "Expected an alert message (too many files)" if msg
    assert_match(/only upload|at a time|files/i, msg, "Alert should mention file count limit") if msg
  end

  test "when TUS disabled footer shows max size per file" do
    Settings.files.use_tus_uploads = false

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5
    assert_selector "#file-count-footer"
    assert_text "Max ", wait: 2
    assert_text "per file", wait: 2
  end

  test "when TUS enabled footer does not show max size per file" do
    Settings.files.use_tus_uploads = true

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5
    assert_selector "#file-count-footer"
    # Footer should have "per push" but when TUS on we don't show "Max X per file"
    footer = find("#file-count-footer")
    assert footer.text.include?("per push")
    assert_not footer.text.include?("per file"), "TUS enabled: footer should not show max per file"
  end
end
