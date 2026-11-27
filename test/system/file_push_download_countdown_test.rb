# frozen_string_literal: true

require "application_system_test_case"

class FilePushDownloadCountdownTest < ApplicationSystemTestCase
  setup do
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    Settings.files.blob_urls_expire_in = "10 minutes"
    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "show page countdown uses the configured download URL expiry" do
    push = Push.create!(kind: :file, payload: "see files", user: @user)
    push.files.attach(io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")), filename: "test-file.txt")

    visit push_path(push)

    assert_text "test-file.txt", wait: 5
    assert_selector "#countdown-timer", wait: 5
    timer = find("#countdown-timer").text
    assert_match(/\A(9|10):\d{2}\z/, timer, "expected a ~10 minute countdown, got #{timer.inspect}")
  end
end
