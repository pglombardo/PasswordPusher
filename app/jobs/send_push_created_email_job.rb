# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(push_id, recipients, locale)
    push = Push.find_by(id: push_id)
    return if push.blank? || push.notify_emails_to.blank?

    successful_recipients = []
    recipients.split(",").map(&:strip).each do |recipient|
      mail = PushCreatedMailer.with(record: push, recipient: recipient, locale: locale).notify
      mail.deliver_now
      successful_recipients << recipient
    rescue => e
      Rails.logger.error "[SendPushCreatedEmailJob] Error sending email to #{recipient}: #{e.message}"
    end
    push.audit_logs.create!(kind: :creation_email_send, user: push.user, recipients: successful_recipients.join(","))
  end
end
