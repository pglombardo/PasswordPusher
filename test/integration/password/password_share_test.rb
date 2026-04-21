# frozen_string_literal: true

require "test_helper"

class PasswordShareTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    Settings.mail.smtp_address = "smtp.example.com"
    @user = users(:one)
    @push = pushes(:test_push)
    sign_in @user
  end

  teardown do
    Settings.reload!
  end

  def test_password_share
    get preview_push_path(@push)

    assert_response :success

    assert_select "input[name='push[share_recipients]']", count: 1
    assert_select "input[name='push[share_locale]']", count: 1

    post share_push_path(@push), params: {push: {share_recipients: "test@example.com", share_locale: "fr"}}
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert_equal 1, @push.share_by_emails.count
    assert_equal "test@example.com", @push.share_by_emails.first.recipients
    assert_equal "fr", @push.share_by_emails.first.locale
  end
end
