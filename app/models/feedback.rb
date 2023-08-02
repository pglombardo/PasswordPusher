class Feedback < MailForm::Base
  include MailForm::Delivery
  append :remote_ip, :user_agent, :referrer

  attribute :name,      validate: true
  attribute :email,     validate: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message,   validate: true
  attribute :control,   validate: /\A95\z/
  attributes :nickname, captcha: true

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    headers = {
      to: Settings.feedback.email,
      from: Settings.mail.mailer_sender,
      subject: Settings.brand.title + ' Feedback',
      'X-PWPUSH-URL' => request.url
    }
    headers
  end
end
