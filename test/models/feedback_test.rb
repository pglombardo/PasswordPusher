# frozen_string_literal: true

require "test_helper"

CONTROL = "97"

class FeedbackTest < ActiveSupport::TestCase
  test "spam is caught and trashed" do
    feedback = Feedback.new(
      control: CONTROL,
      name: "Joey",
      email: "joey@blah.com",
      message: <<~SPAMMSG
        Hello pwpush.com owner,

        We can help you grow your online presence and attract more customers to your business with our Top SEO Services.

        Our team of experts can improve your Google and YouTube Ranking, optimize your Google Maps listing, provide Professional Content for your website, and increase your Website Traffic.

        Don't miss this opportunity to grow your business and stay ahead of the competition.

        =>> https://some-spam-site.com

        Best regards,
        Mullet
      SPAMMSG
    )
    assert_not feedback.valid?
  end

  test "valid emails are allowed through" do
    feedback = Feedback.new(
      control: CONTROL,
      name: "Joey",
      email: "joey@blah.com",
      message: <<~MSG
        Hello!  We love Password Pusher!  It's the best!
      MSG
    )
    assert feedback.valid?
  end

  test "bad control is blocked" do
    feedback = Feedback.new(
      control: 1,
      name: "Joey",
      email: "joey@blah.com",
      message: <<~MSG
        Hello!  We love Password Pusher!  It's the best!
      MSG
    )
    assert_not feedback.valid?
  end
end
