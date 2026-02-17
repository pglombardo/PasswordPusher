# frozen_string_literal: true

require "application_system_test_case"

class FilePushUploadUiTest < ApplicationSystemTestCase
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
    restore_tus_related_settings
  end

  test "progress bar container is present on file push form" do
    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5
    # Progress bar list is in the DOM (may be empty until upload starts)
    assert_selector "ul#progress-bars", wait: 2, visible: :all
    assert_selector "ul#progress-bars[aria-label='Upload progress']", visible: :all
  end

  test "when too many files selected no extra file is added to list" do
    Settings.files.max_file_uploads = 1

    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    find("#selected-files", visible: :all)

    file_path1 = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    file_path2 = Rails.root.join("test", "fixtures", "files", "monkey.png")
    msg = nil
    begin
      msg = accept_alert(wait: 5) do
        attach_file "push_files", [file_path1, file_path2], make_visible: true
      end
    rescue Capybara::ModalNotFound
      # Driver may not support alert modal; we still assert limit was enforced
    end

    count_after = find("#selected-files", visible: :all).all("li", visible: :all).size
    assert count_after <= 1, "At most one file should be in the list when limit is 1"
    assert_match(/only upload|at a time|files/i, msg, "Alert should mention file count limit") if msg.present?
  end

  test "when file pushes enabled footer shows max size per file" do
    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5
    assert_selector "#file-count-footer"
    footer = find("#file-count-footer")
    assert footer.text.include?("per push"), "Footer should show upload limit per push"
    assert footer.text.include?("per file"), "Footer should show max size per file when using TUS"
  end

  test "file push creates push and lists file" do
    visit new_push_path(tab: "files")
    assert_selector "a.nav-link.active", text: /file/i, wait: 5

    file_path = Rails.root.join("test", "fixtures", "files", "test-file.txt")
    attach_file "push_files", file_path, make_visible: true

    # Wait for TUS upload to complete: file row appears in #selected-files
    assert_selector "#selected-files li.selected-file", wait: 15
    assert_text "test-file.txt", wait: 5

    click_button "Push It!"

    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 10
    assert_text "Push Preview", wait: 5

    # View the push to see the file listed
    token = page.current_path.split("/")[2]
    visit "/p/#{token}"

    assert_text "test-file.txt", wait: 5
  end
end
