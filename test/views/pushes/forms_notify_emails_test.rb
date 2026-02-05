# frozen_string_literal: true

require "test_helper"

class PushesFormsNotifyEmailsViewTest < ActionView::TestCase
  include LanguageHelper

  setup do
    def controller.action_name
      "new"
    end
  end

  test "form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, true) do
        render partial: "pushes/form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 1
  end

  test "form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, false) do
        render partial: "pushes/form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 0
  end

  test "form partial hides notify_emails fields when smtp not configured" do
    view.instance_variable_set(:@push, Push.new(kind: "text"))
    view.stub(:smtp_configured?, false) do
      view.stub(:user_signed_in?, true) do
        render partial: "pushes/form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 0
  end

  test "url_form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "url"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, true) do
        render partial: "pushes/url_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 1
  end

  test "url_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "url"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, false) do
        render partial: "pushes/url_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 0
  end

  test "files_form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "file"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, true) do
        render partial: "pushes/files_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 1
  end

  test "files_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "file"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, false) do
        render partial: "pushes/files_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 0
  end

  test "qr_form partial shows notify_emails fields when smtp configured and user signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "qr"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, true) do
        render partial: "pushes/qr_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 1
  end

  test "qr_form partial hides notify_emails fields when user not signed in" do
    view.instance_variable_set(:@push, Push.new(kind: "qr"))
    view.stub(:smtp_configured?, true) do
      view.stub(:user_signed_in?, false) do
        render partial: "pushes/qr_form"
      end
    end
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 0
  end
end
