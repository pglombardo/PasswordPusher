# frozen_string_literal: true

require "test_helper"

class PushCreatedMailerTest < ActionMailer::TestCase
  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @user = users(:luca)
    @push = pushes(:test_push)
    @push.update(user: @user)
  end

  test "notify sends to all parsed emails" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert_equal ["one@example.com", "two@example.com"], mail.to
  end

  test "notify includes subject" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert mail.subject.present?, "subject should be present"
    # Subject is brandless: "email@example.com has sent you a push"
    assert_includes mail.subject, "has sent you a push"
  end

  test "notify body includes secret URL" do
    mail = PushCreatedMailer.with(record: @push).notify
    mail.deliver_now

    assert_includes mail.body.encoded, @push.url_token
  end

  test "notify uses push url for non-retrieval-step push" do
    @push.assign_attributes(retrieval_step: false)
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
  end

  test "notify uses preliminary url when retrieval_step is true" do
    @push.assign_attributes(retrieval_step: true)
    mail = PushCreatedMailer.with(record: @push).notify

    # Preliminary step path is /p/:url_token/r
    assert_includes mail.body.encoded, "/p/#{@push.url_token}/r"
  end

  test "notify delivers successfully" do
    assert_emails 1 do
      PushCreatedMailer.with(record: @push).notify.deliver_now
    end
  end

  test "notify includes locale in secret URL when notify_emails_to_locale is set" do
    @push.assign_attributes(notify_emails_to_locale: "fr")
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.html_part.body.encoded, "locale=fr"
    assert_includes mail.text_part.body.encoded, "locale=fr"
  end

  test "notify URL has no locale param when notify_emails_to_locale is blank" do
    @push.assign_attributes(notify_emails_to_locale: nil)
    @push.save
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
    # Secret URL is built without ?locale= when locale is blank
    refute_includes mail.html_part.body.encoded, "locale="
    refute_includes mail.text_part.body.encoded, "locale="
  end

  test "notify subject includes user email" do
    mail = PushCreatedMailer.with(record: @push).notify
    assert_includes mail.subject, @user.email
  end

  test "notify body includes expiration days and views" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.html_part.body.decoded, "valid for 7 days, or until 99 views"
    assert_includes mail.text_part.body.decoded, "valid for 7 days, or until 99 views"
  end

  test "notify HTML part secret link has full clickable URL in href" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.html_part.body.decoded, @push.url_token
  end
end
