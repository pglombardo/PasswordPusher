# frozen_string_literal: true

require "application_system_test_case"

class FilePushSizeLimitSystemTest < ApplicationSystemTestCase
  setup do
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    Settings.files.max_file_size = "1KB"
    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "web form shows an over-limit error before upload starts" do
    visit new_push_path(tab: "files")
    assert_selector "h5", text: "Add Files...", wait: 5
    assert_text "Maximum size per file is 1KB."

    attach_file "push_files", Rails.root.join("test/fixtures/files/monkey.png"), make_visible: true

    assert_selector "#file-size-error", visible: true, wait: 5
    assert_text "too large"
    assert_text "monkey.png"
    assert_no_selector ".selected-file", text: "monkey.png"
  end
end
