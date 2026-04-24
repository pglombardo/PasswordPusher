# frozen_string_literal: true

require "test_helper"

class PasswordNotifyByEmailTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    Settings.mail.smtp_address = "smtp.example.com"
    @push = pushes(:test_push)
    @user = @push.user
    sign_in @user
  end

  teardown do
    Settings.reload!
  end

  def test_password_notify_by_email
    get preview_push_path(@push)

    assert_response :success

    assert_select "input[name='push[notify_by_email_recipients]']", count: 1
    assert_select "input[name='push[notify_by_email_locale]']", count: 1

    job = assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post notify_by_email_push_path(@push), params: {push: {notify_by_email_recipients: "test@example.com", notify_by_email_locale: "fr"}}
      assert_response :redirect

      follow_redirect!
      assert_response :success
    end

    notify_by_email = NotifyByEmail.find(job.arguments.first)
    assert_equal "test@example.com", notify_by_email.recipients
    assert_equal "fr", notify_by_email.locale
  end
end
