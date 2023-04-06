class Feedback < MailForm::Base
  include MailForm::Delivery
  append :remote_ip, :user_agent, :referrer

  attribute :name,      validate: true
  attribute :email,     validate: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message,   validate: true
  attribute :nickname,  captcha: true
  attribute :control,   validate: /\A9\z/

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    headers = {
      to: Settings.feedback.email,
      from: Settings.mail.mailer_sender
    }

    headers[:subject] = Settings.brand.title + ' Feedback'

    headers
  end
end
