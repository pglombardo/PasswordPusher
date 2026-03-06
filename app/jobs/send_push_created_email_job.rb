# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(push_id)
    push = Push.find_by(id: push_id)
    return if push.blank? || push.notify_emails_to.blank?

    PushCreatedMailer.with(record: push).notify.deliver_now
    push.audit_logs.create!(kind: :notify_email_sent, user: push.user)
  end
end
