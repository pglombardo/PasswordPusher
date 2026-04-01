# frozen_string_literal: true

require "test_helper"

class PushesFormsNotifyEmailsViewTest < ActionView::TestCase
  include LanguageHelper

  setup do
    @default_disable_logins = Settings.disable_logins
    @default_enable_user_account_emails = Settings.enable_user_account_emails
    Settings.disable_logins = false
    Settings.enable_user_account_emails = true
    def controller.action_name
      "new"
    end

    # url_for in _push_locale_dropdown needs the current route (same as GET /p/new).
    Rails.application.routes.default_url_options[:host] = "test.host"
    controller.request.env["PATH_INFO"] = "/p/new"
    controller.request.path_parameters =
      Rails.application.routes.recognize_path("/p/new", method: :get)
  end

  teardown do
    Settings.disable_logins = @default_disable_logins
    Settings.enable_user_account_emails = @default_enable_user_account_emails
  end

  test "form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:user_signed_in?, true) do
      render partial: "pushes/form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
  end

  test "form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:user_signed_in?, false) do
      render partial: "pushes/form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "form partial hides notify_emails fields when enable_user_account_emails is false" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:user_signed_in?, true) do
      view.stub(:show_notify_emails_field?, false) do
        render partial: "pushes/form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "url_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "url"))
    view.stub(:user_signed_in?, false) do
      render partial: "pushes/url_form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "files_form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "file"))
    view.stub(:user_signed_in?, true) do
      render partial: "pushes/files_form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
  end

  test "files_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "file"))
    view.stub(:user_signed_in?, false) do
      render partial: "pushes/files_form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "qr_form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "qr"))
    view.stub(:user_signed_in?, true) do
      render partial: "pushes/qr_form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
  end

  test "qr_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "qr"))
    view.stub(:user_signed_in?, false) do
      render partial: "pushes/qr_form"
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end
end
