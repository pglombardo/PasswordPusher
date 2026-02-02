# frozen_string_literal: true

class SendPushCreatedEmailJob < ApplicationJob
  queue_as :default

  def perform(push)
    return if push.notify_emails_to.blank?

    PushCreatedMailer.with(record: push).notify.deliver_now
  end
end
