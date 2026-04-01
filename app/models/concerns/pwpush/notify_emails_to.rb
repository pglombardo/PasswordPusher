# frozen_string_literal: true

module Pwpush
  module NotifyEmailsTo
    extend ActiveSupport::Concern

    included do
      has_encrypted :notify_emails_to, :notify_emails_to_locale
      validates :notify_emails_to, multiple_emails: true, allow_blank: true
      validates :notify_emails_to_locale,
        inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true
    end

    # Parses a comma-separated email string into an array of stripped, non-blank strings.
    def self.parse_emails(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    # Send creation email when notify_emails_to is present (developer feedback: run inline).
    # (OSS: always allow; Pro gates with account_is_premium?)
    def send_creation_emails
      return nil if notify_emails_to.blank?

      SendPushCreatedEmailJob.perform_later(id)
    end
  end
end
