# frozen_string_literal: true

module Pwpush
  module NotifyEmailsTo
    extend ActiveSupport::Concern

    included do
      has_encrypted :notify_emails_to, :notify_emails_to_locale

      # Validations for email notifications
      validates :notify_emails_to, multiple_emails: true
      validate :notify_emails_to_for_creation, on: :create
      validate :notify_emails_to_for_update, on: :update

      validates :notify_emails_to_locale, inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true, allow_nil: true, on: :create
      validate :notify_emails_to_locale_for_creation, on: :create
      validate :notify_emails_to_locale_for_update, on: :update
    end

    # Parses a comma-separated email string into an array of stripped, non-blank strings.
    def self.parse_emails(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    # Send creation email when notify_emails_to is present
    def send_creation_emails
      return nil if notify_emails_to.blank?

      SendPushCreatedEmailJob.perform_later(id)
    end

    private

    ## notify_emails_to_for_creation
    #
    # It checks if sending emails feature is enabled. If it is not, it adds an error.
    #
    # @return [nil]
    def notify_emails_to_for_creation
      return nil unless notify_emails_to.present?

      unless Settings.enable_user_account_emails
        errors.add(:notify_emails_to, _("is using emails, but sending emails feature is not enabled."))
      end

      nil
    end

    ## notify_emails_to_for_update
    #
    # It prevents the notify_emails_to attribute from being updated
    #
    # @return [nil]
    def notify_emails_to_for_update
      if will_save_change_to_notify_emails_to?
        errors.add(:notify_emails_to, _("is not updatable."))
      end
    end

    ## notify_emails_to_locale_for_creation
    #
    # It checks notify_emails_to_locale. If sending emails feature is not enabled, it adds an error.
    #
    # @return [nil]
    def notify_emails_to_locale_for_creation
      return unless notify_emails_to_locale.present?

      unless Settings.enable_user_account_emails
        errors.add(:notify_emails_to_locale, _("is using emails, but sending emails feature is not enabled."))
      end
    end

    ## notify_emails_to_locale_for_update
    #
    # It prevents the notify_emails_to_locale attribute from being updated
    #
    # @return [nil]
    def notify_emails_to_locale_for_update
      if will_save_change_to_notify_emails_to_locale?
        errors.add(:notify_emails_to_locale, _("is not updatable."))
      end
    end
  end
end
