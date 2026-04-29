# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(notify_by_email_id)
    notify_by_email = NotifyByEmail.find_by(id: notify_by_email_id)

    return unless notify_by_email
    return unless notify_by_email.pending?
    return unless notify_by_email.recipients.present?

    notify_by_email.processing!

    push = notify_by_email.push
    locale = notify_by_email.locale
    recipients = notify_by_email.recipients.split(",").map(&:strip)

    successful_sends = []
    recipients.each do |recipient|
      mail = PushCreatedMailer.with(record: push, recipient: recipient, locale: locale).notify
      mail.deliver_now
      successful_sends << recipient
    rescue => e
      Rails.logger.error "[SendPushCreatedEmailJob] Error sending email: #{e.message}"
    end

    status = if successful_sends.size == recipients.size
      :completed
    elsif successful_sends.empty?
      :fully_failed
    else
      :partially_failed
    end

    notify_by_email.update!(successful_sends: successful_sends.join(","), status: status, proceed_at: Time.current)
  end
end
