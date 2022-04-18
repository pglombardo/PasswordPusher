class Feedback < MailForm::Base
  include MailForm::Delivery
  append :remote_ip, :user_agent, :referrer

  attribute :name,      validate: true
  attribute :email,     validate: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message,   validate: true
  attribute :nickname,  captcha: true
  attribute :control,   validate: /4/

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    {
      subject: _('Password Pusher Feedback'),
      to: 'feedback@pwpush.com',
      from: Settings.mail.mailer_sender
    }
  end
end
