# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(push_id)
    push = Push.find_by(id: push_id)
    return if push.blank? || push.notify_emails_to.blank?

    mail = PushCreatedMailer.with(record: push).notify
    mail.message.raise_delivery_errors = true
    Rails.logger.info "[SendPushCreatedEmailJob] Sending push created email for push #{push.url_token} to #{mail.message.to.size} recipient(s)"
    result = mail.deliver_now
    Rails.logger.info "[SendPushCreatedEmailJob] Successfully sent push created email for push #{push.url_token} (Message-ID: #{result.message_id})"
    push.audit_logs.create!(kind: :creation_email_send, user: push.user)
  end
end
