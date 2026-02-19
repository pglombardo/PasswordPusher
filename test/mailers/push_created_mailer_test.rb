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

  test "notify body includes valid for sentence with duration and views" do
    @push.update!(expire_after_days: 7, expire_after_views: 5)
    mail = PushCreatedMailer.with(record: @push).notify
    body = mail.body.encoded
    assert_match(/valid for .* or until .* views/i, body, "body should explain link validity with duration and view limit")
    assert_includes body, "7", "full duration for 7 days should include 7"
    assert_includes body, "5", "view limit should appear"
  end

  test "notify body displays full duration for 1 day expiry" do
    @push.update!(expire_after_days: 1, expire_after_views: 3)
    mail = PushCreatedMailer.with(record: @push).notify
    body = mail.body.encoded
    # Full duration format: "1 day(s), 0 hour(s) and 0 minute(s)" or similar
    assert_includes body, "1", "1 day expiry should show 1"
    assert body.include?("day") || body.include?("hour"), "duration should include day or hour unit"
  end

  test "notify body displays full duration for 7 days expiry" do
    @push.update!(expire_after_days: 7, expire_after_views: 10)
    mail = PushCreatedMailer.with(record: @push).notify
    body = mail.body.encoded
    assert_includes body, "7", "7 day expiry should show 7"
    assert_includes body, "10", "view limit should show 10"
    assert body.include?("day"), "duration should include day unit"
  end

  test "notify text part includes duration and views" do
    @push.update!(expire_after_days: 2, expire_after_views: 4)
    mail = PushCreatedMailer.with(record: @push).notify
    text_part = mail.text_part || mail
    text_body = text_part.body.encoded
    assert_includes text_body, "2", "text part should include days in duration"
    assert_includes text_body, "4", "text part should include view limit"
  end

  test "notify with single email sends to one recipient" do
    @push.update!(notify_emails_to: "only@example.com")
    mail = PushCreatedMailer.with(record: @push).notify
    assert_equal ["only@example.com"], mail.to
  end

  test "notify body includes time unit words in duration" do
    @push.update!(expire_after_days: 1, expire_after_views: 1)
    mail = PushCreatedMailer.with(record: @push).notify
    body = mail.body.encoded
    # Full duration format includes day(s), hour(s), and/or minute(s)
    assert body.include?("day") || body.include?("hour") || body.include?("minute"),
      "body should include at least one time unit (day, hour, minute)"
  end

  test "notify multipart mail has both html and text parts with duration" do
    @push.update!(expire_after_days: 5, expire_after_views: 2)
    mail = PushCreatedMailer.with(record: @push).notify
    assert mail.multipart?, "notify should be multipart when both templates exist"
    assert_includes mail.html_part.body.encoded, "5", "HTML part should include duration"
    assert_includes mail.text_part.body.encoded, "5", "text part should include duration"
    assert_includes mail.text_part.body.encoded, "2", "text part should include view limit"
  end

  test "notify body includes secret link phrase" do
    mail = PushCreatedMailer.with(record: @push).notify
    body = mail.body.encoded
    assert body.include?("Secret link") || body.include?("secret"), "body should mention secret link"
  end

  test "notify HTML part has expected structure" do
    mail = PushCreatedMailer.with(record: @push).notify
    html = mail.html_part&.body&.decoded || mail.body.decoded
    assert_match(/<h1[^>]*>/, html, "HTML should have h1 heading")
    assert_match(/<a\s+href=.*#{Regexp.escape(@push.url_token)}/, html, "HTML should have secret link anchor with url_token")
    assert_match(/Important Notes/i, html, "HTML should have Important Notes section")
    assert_match(/<ul/i, html, "HTML should have list")
    assert_match(/<li/i, html, "HTML should have list items")
  end

  test "notify text part has expected structure" do
    mail = PushCreatedMailer.with(record: @push).notify
    text = mail.text_part&.body&.decoded || mail.body.decoded
    assert_includes text, @push.url_token, "text part should include secret URL"
    assert_match(/Secret link/i, text, "text part should mention secret link")
    assert_match(/Important Notes/i, text, "text part should have Important Notes")
  end

  test "notify HTML part has exactly three list items in Important Notes" do
    mail = PushCreatedMailer.with(record: @push).notify
    html = mail.html_part&.body&.decoded || mail.body.decoded
    list_items = html.scan(/<li\b/i)
    assert_equal 3, list_items.size, "Important Notes section should have exactly 3 list items"
  end

  test "notify HTML part secret link has full clickable URL in href" do
    mail = PushCreatedMailer.with(record: @push).notify
    html = mail.html_part&.body&.decoded || mail.body.decoded
    # Link must be a full URL (scheme + host) so it is clickable in email clients
    assert_match(
      %r{<a\s+[^>]*href="https?://[^"]*/p/#{Regexp.escape(@push.url_token)}(?:\?[^"]*)?"},
      html,
      "HTML should have anchor with full URL in href (scheme + host + path)"
    )
  end

  test "notify HTML part secret link text equals href URL" do
    mail = PushCreatedMailer.with(record: @push).notify
    html = mail.html_part&.body&.decoded || mail.body.decoded
    m = html.match(%r{<a\s+[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>})
    assert m, "HTML should have secret link anchor with href and text"
    assert_equal m[1], m[2].strip, "link text should equal href URL (template: <a href=\"@secret_url\">@secret_url</a>)"
  end
end
