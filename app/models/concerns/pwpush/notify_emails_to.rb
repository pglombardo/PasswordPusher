# frozen_string_literal: true

module Pwpush
  module NotifyEmailsTo
    extend ActiveSupport::Concern

    included do
      validates :notify_emails_to, multiple_emails: true, allow_blank: true
      validates :notify_emails_to_locale,
        inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true
    end

    # Parses a comma-separated email string into an array of stripped, non-blank strings.
    def self.parse_emails(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    # Enqueue job to send creation email if notify_emails_to is present.
    def send_creation_emails
      return if notify_emails_to.blank?

      if Rails.env.development?
        # In development we run the job inline (perform_now) so emails are sent immediately
        # without requiring a background worker. This makes it easy to test with Mailbin or
        # similar and avoids needing to run a job queue locally.
        SendPushCreatedEmailJob.perform_now(id)
      else
        SendPushCreatedEmailJob.perform_later(id)
      end
    end
  end
end
