# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(notify_by_email_id)
    notify_by_email = NotifyByEmail.find_by(id: notify_by_email_id)

    if notify_by_email.nil?
      Rails.logger.error "[SendPushCreatedEmailJob] NotifyByEmail not found: #{notify_by_email_id}"

      return
    end

    if notify_by_email.recipients.blank?
      notify_by_email.update(status: :failed, error_message: _("No recipients found."), proceed_at: Time.current)

      return
    end

    unless Settings.notify_by_email_available?
      notify_by_email.update(status: :failed, error_message: _("Notifying by email is not available."), proceed_at: Time.current)

      return
    end

    return unless notify_by_email.pending?

    notify_by_email.processing!

    push = notify_by_email.push
    locale = notify_by_email.locale
    recipients = notify_by_email.recipients.split(",").map(&:strip)

    if push.expired?
      notify_by_email.update(status: :failed, error_message: _("Push already expired."), proceed_at: Time.current)

      return
    end

    successful_sends = []
    recipients.each do |recipient|
      mail = PushCreatedMailer.with(push: push, recipient: recipient, locale: locale).notify
      mail.deliver_now
      successful_sends << recipient
    rescue => e
      Rails.logger.error "[SendPushCreatedEmailJob] Error sending email: #{e.message}"
    end

    status, error_message = if successful_sends.size == recipients.size
      [:completed, nil]
    elsif successful_sends.empty?
      [:failed, I18n._("No emails were sent successfully.")]
    else
      [:partially_failed, I18n._("Some emails could not be sent.")]
    end

    notify_by_email.update!(successful_sends: successful_sends.join(","), status: status, error_message: error_message, proceed_at: Time.current)
  end

rescue => e
  Rails.logger.error "[SendPushCreatedEmailJob] Error sending email: #{e.message}"

  notify_by_email.update(status: :failed, error_message: e.message, proceed_at: Time.current)
end
