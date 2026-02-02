# frozen_string_literal: true

module Pwpush
  module NotifyEmailsTo
    extend ActiveSupport::Concern

    included do
      validates :notify_emails_to, multiple_emails: true, allow_blank: true
    end

    # Enqueue job to send creation email if notify_emails_to is present.
    def send_creation_emails
      return if notify_emails_to.blank?

      if Rails.env.development?
        SendPushCreatedEmailJob.perform_now(self)
      else
        SendPushCreatedEmailJob.perform_later(self)
      end
    end
  end
end
