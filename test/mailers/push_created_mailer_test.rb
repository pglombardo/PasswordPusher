# frozen_string_literal: true

require "test_helper"

class PushCreatedMailerTest < ActionMailer::TestCase
  setup do
    Rails.application.routes.default_url_options[:host] = "localhost:3000"
    @user = users(:luca)
    @push = pushes(:test_push)
    @push.update(user: @user)
  end

  test "notify sends to emails" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert_equal ["one@example.com"], mail.to
  end

  test "notify includes subject" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert mail.subject.present?, "subject should be present"
    # Subject is brandless: "email@example.com has sent you a push"
    assert_includes mail.subject, "has sent you a push"
  end

  test "notify body includes secret URL" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify
    mail.deliver_now

    assert_includes mail.body.encoded, @push.url_token
  end

  test "notify uses push url for non-retrieval-step push" do
    @push.assign_attributes(retrieval_step: false)
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
  end

  test "notify uses preliminary url when retrieval_step is true" do
    @push.assign_attributes(retrieval_step: true)
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    # Preliminary step path is /p/:url_token/r
    assert_includes mail.body.encoded, "/p/#{@push.url_token}/r"
  end

  test "notify delivers successfully" do
    assert_emails 1 do
      PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify.deliver_now
    end
  end

  test "notify includes locale in secret URL when notify_by_email_locale is set" do
    @push.assign_attributes(notify_by_email_locale: "fr")
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com", locale: "fr").notify

    assert_includes mail.html_part.body.encoded, "locale=fr"
    assert_includes mail.text_part.body.encoded, "locale=fr"
  end

  test "notify URL has no locale param when notify_by_email_locale is blank" do
    @push.assign_attributes(notify_by_email_locale: nil)
    @push.save
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
    # Secret URL is built without ?locale= when locale is blank
    refute_includes mail.html_part.body.encoded, "locale="
    refute_includes mail.text_part.body.encoded, "locale="
  end

  test "notify subject includes user email" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify
    assert_includes mail.subject, @user.email
  end

  test "notify body includes expiration days and views" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert_includes mail.html_part.body.decoded, "valid for 7 days, or until 99 views"
    assert_includes mail.text_part.body.decoded, "valid for 7 days, or until 99 views"
  end

  test "notify HTML part secret link has full clickable URL in href" do
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify

    assert_includes mail.html_part.body.decoded, @push.url_token
  end

  test "notify secret URL uses https if FORCE_SSL is set" do
    ENV.stub(:key?, true) do
      mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify
      assert_includes mail.body.encoded, "https://"
    end
  end

  test "notify secret URL uses override_base_url if set" do
    Settings.override_base_url = "https://custom.example.com"
    mail = PushCreatedMailer.with(push: @push, recipient: "one@example.com").notify
    assert_includes mail.body.encoded, "https://custom.example.com"
  ensure
    Settings.reload!
  end
end
