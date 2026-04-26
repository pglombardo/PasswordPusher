# frozen_string_literal: true

require "application_system_test_case"

class NotifyByEmailTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.mail.smtp_address = "smtp.example.com"
    @user = users(:giuliana)
    sign_in @user

    # Get the test push from fixtures
    @push = pushes(:test_push)
  end

  teardown do
    Settings.reload!
    sign_out :user
  end

  test "notify by email with valid recipients" do
    visit preview_push_path(@push)
    click_on "Notify via Email"

    assert_selector "input[name='push[notify_by_email_recipients]']", count: 1
    assert_selector "input[name='push[notify_by_email_locale]']", count: 1, visible: :hidden

    fill_in "push[notify_by_email_recipients]", with: "test@example.com"
    click_on "Send Emails"

    assert_text "Recipient(s) are added to the queue to be sent."
  end

  test "notify by email with invalid recipients" do
    visit preview_push_path(@push)
    click_on "Notify via Email"

    fill_in "push[notify_by_email_recipients]", with: "test@example.com, invalid-email"
    click_on "Send Emails"

    assert_text "Notify by email recipients contains invalid email(s)."
  end
end
