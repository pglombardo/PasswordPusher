# frozen_string_literal: true

require "test_helper"

class PushCreatedMailerTest < ActionMailer::TestCase
  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @push = Push.create!(
      kind: "text",
      payload: "secret",
      url_token: "abc123token",
      retrieval_step: false,
      notify_emails_to: "one@example.com, two@example.com",
      notify_emails_to_locale: "en"
    )
  end

  test "notify sends to all parsed emails" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert_equal ["one@example.com", "two@example.com"], mail.to
  end

  test "notify includes subject" do
    mail = PushCreatedMailer.with(record: @push).notify

    assert mail.subject.present?, "subject should be present"
    # Subject is brandless: "Someone has sent you a Push" or "email@example.com has sent you a Push"
    assert_includes mail.subject, "has sent you a Push"
  end

  test "notify body includes secret URL" do
    mail = PushCreatedMailer.with(record: @push).notify
    mail.deliver_now

    assert_includes mail.body.encoded, @push.url_token
  end

  test "notify uses push url for non-retrieval-step push" do
    @push.update!(retrieval_step: false)
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
  end

  test "notify uses preliminary url when retrieval_step is true" do
    @push.update!(retrieval_step: true)
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
    @push.update!(notify_emails_to_locale: "fr")
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.body.encoded, "locale=fr"
  end

  test "notify URL has no locale param when notify_emails_to_locale is blank" do
    @push.update!(notify_emails_to_locale: nil)
    mail = PushCreatedMailer.with(record: @push).notify

    assert_includes mail.body.encoded, "/p/#{@push.url_token}"
    # Secret URL is built without ?locale= when locale is blank
    assert_no_match(/\?locale=/, mail.body.encoded)
  end

  test "notify subject includes user email when push has user" do
    user = users(:luca)
    @push.update_columns(user_id: user.id)
    mail = PushCreatedMailer.with(record: @push).notify
    assert_includes mail.subject, user.email
  end

  test "notify subject includes Someone when push has no user" do
    @push.update_columns(user_id: nil)
    mail = PushCreatedMailer.with(record: @push).notify
    assert_includes mail.subject, "Someone"
  end

  test "notify body includes expiration days and views" do
    @push.update!(expire_after_days: 3, expire_after_views: 10)
    mail = PushCreatedMailer.with(record: @push).notify
    assert_includes mail.body.encoded, "3"
    assert_includes mail.body.encoded, "10"
  end
end
