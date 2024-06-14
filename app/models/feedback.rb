# frozen_string_literal: true

class Feedback < MailForm::Base
  include MailForm::Delivery
  append :remote_ip, :user_agent, :referrer

  attribute :name, validate: true
  attribute :email, validate: /\A([\w.%+-]+)@([\w-]+\.)+(\w{2,})\z/i
  attribute :message, validate: true
  attribute :control, validate: /\A97\z/
  attributes :nickname, captcha: true

  # rubocop:disable Layout/LineLength
  validates :message, format: {without: /\b(SEO|offer|ranking|rankings|transformative|engagement|click here|absolutely free|Money Back|affiliate|commission|marketing|promote)\b+/i,
                               message: "spam detected"}
  # rubocop:enable Layout/LineLength

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    {
      :to => Settings.feedback.email,
      :from => Settings.mail.mailer_sender,
      :subject => "#{Settings.brand.title} Feedback",
      :reply_to => email,
      "X-PWPUSH-URL" => request.url
    }
  end
end
