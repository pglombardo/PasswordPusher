# frozen_string_literal: true

require "test_helper"

class ShareMessageHelperTest < ActionView::TestCase
  include PushesHelper

  setup do
    @push = pushes(:test_push)
    @secret_url = "https://example.com/p/testtoken123"
  end

  test "push_share_message_text includes secret url and expiration notes" do
    message = push_share_message_text(@push, secret_url: @secret_url)

    assert_includes message, @secret_url
    assert_includes message, "Secret link:"
    assert_includes message, "IMPORTANT NOTES:"
    assert_includes message, @push.views_remaining.to_s
    assert_includes message, @push.days_remaining.to_s
  end

  test "push_share_message_text includes passphrase note when passphrase set" do
    @push.passphrase = "secret"
    message = push_share_message_text(@push, secret_url: @secret_url)

    assert_includes message, "passphrase"
  end

  test "push_share_message_text omits passphrase note when passphrase blank" do
    @push.passphrase = ""
    message = push_share_message_text(@push, secret_url: @secret_url)

    assert_not_includes message.downcase, "passphrase"
  end
end
