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
      validate :notify_emails_to_attributes_unchanged_on_update, on: :update
    end

    # Parses a comma-separated email string into an array of stripped, non-blank strings.
    def self.parse_emails(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    # Enqueue job to send creation email if notify_emails_to is present.
    # (OSS: always allow; Pro gates with account_is_premium?)
    #
    # In development we use perform_now so emails are sent immediately without running a
    # background job processor (e.g. Solid Queue), which makes it easy to try the feature
    # with Mailbin or similar. Tradeoff: job exceptions surface inline in the request rather
    # than asynchronously. To get async behavior in development, use perform_later here and
    # run your job backend; tests use perform_later and rely on ActiveJob test helpers.
    def send_creation_emails
      return nil if notify_emails_to.blank?

      if Rails.env.development?
        SendPushCreatedEmailJob.perform_now(id)
      else
        SendPushCreatedEmailJob.perform_later(id)
      end
      nil
    end

    private

    def notify_emails_to_attributes_unchanged_on_update
      return unless notify_emails_to_changed? || notify_emails_to_locale_changed?

      message = I18n._("cannot be updated after creation")
      errors.add(:notify_emails_to, message) if notify_emails_to_changed?
      errors.add(:notify_emails_to_locale, message) if notify_emails_to_locale_changed?
    end
  end
end
