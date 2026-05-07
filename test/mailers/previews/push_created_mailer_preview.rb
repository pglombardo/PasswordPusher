# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/push_created_mailer
class PushCreatedMailerPreview < ActionMailer::Preview
  # Preview the push notification email
  # http://localhost:3000/rails/mailers/push_created_mailer/notify
  def notify
    push = sample_push
    PushCreatedMailer.with(
      push: push,
      recipient: "recipient@example.com"
    ).notify
  end

  # Preview with a specific locale (e.g., Spanish)
  # http://localhost:3000/rails/mailers/push_created_mailer/notify_with_locale
  def notify_with_locale
    push = sample_push
    PushCreatedMailer.with(
      push: push,
      recipient: "recipient@example.com",
      locale: "es"
    ).notify
  end

  # Preview with retrieval step enabled
  # http://localhost:3000/rails/mailers/push_created_mailer/notify_with_retrieval_step
  def notify_with_retrieval_step
    push = sample_push(retrieval_step: true)
    PushCreatedMailer.with(
      push: push,
      recipient: "recipient@example.com"
    ).notify
  end

  private

  def sample_push(options = {})
    user = build_sample_user

    push = Push.new(
      kind: :text,
      payload: "This is a sample secret payload for preview purposes.",
      expire_after_days: 7,
      expire_after_views: 5,
      retrieval_step: options[:retrieval_step] || false,
      user: user,
      created_at: Time.current
    )

    # Apply any additional options
    push.retrieval_step = options[:retrieval_step] if options.key?(:retrieval_step)

    # Need to trigger validations to set the default values
    push.valid?

    push
  end

  def build_sample_user
    User.new(
      email: "sender@example.com",
      created_at: Time.current
    )
  end
end
