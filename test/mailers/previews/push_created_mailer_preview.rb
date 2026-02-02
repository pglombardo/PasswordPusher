# Preview at http://localhost:3000/rails/mailers/push_created_mailer/notify
class PushCreatedMailerPreview < ActionMailer::Preview
  def notify
    push = Push.new(
      url_token: "preview123",
      retrieval_step: false,
      notify_emails_to: "recipient@example.com",
      notify_emails_to_locale: "en"
    )
    push.define_singleton_method(:persisted?) { true }
    PushCreatedMailer.with(record: push).notify
  end
end
