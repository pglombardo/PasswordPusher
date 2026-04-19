# frozen_string_literal: true

module Pwpush
  module NotifyEmailsTo
    extend ActiveSupport::Concern
    MAX_SHARE_BY_EMAILS = 5

    included do
      has_encrypted :notify_emails_to, :notify_emails_to_locale
      attr_accessor :notify_emails_to_locale
      attr_accessor :notify_emails_to_recipients

      # Validations for email notifications
      validate :notify_emails_to_for_creation, on: :create
      validate :notify_emails_to_for_update, on: :update

      validates :notify_emails_to_locale, inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true, allow_nil: true, on: :create

      validates :notify_emails_to_recipients, multiple_emails: {max_emails: MAX_SHARE_BY_EMAILS}
    end

    # Send creation email when notify_emails_to is present
    def send_creation_emails
      recipients = notify_emails_to_recipients
      return nil if recipients.blank?

      locale = notify_emails_to_locale

      SendPushCreatedEmailJob.perform_later(id, recipients, locale)
    end

    private

    ## notify_emails_to_for_creation
    #
    # It checks if sending emails feature is enabled. If it is not, it adds an error.
    #
    # @return [nil]
    def notify_emails_to_for_creation
      return nil unless notify_emails_to.present?

      unless Settings.mail.smtp_address.present?
        errors.add(:notify_emails_to, _("is using emails, but sending emails feature is not enabled"))
      end

      if notify_emails_to.split(",").count > MAX_SHARE_BY_EMAILS
        errors.add(:base, _("You can share this push with up to %{count} email(s)") % {count: MAX_SHARE_BY_EMAILS})
      end

      unless user.present?
        errors.add(:notify_emails_to, _("cannot be set if owner is not known"))
      end

      nil
    end

    ## notify_emails_to_for_update
    #
    # It prevents the notify_emails_to attribute from being updated
    #
    # @return [nil]
    def notify_emails_to_for_update
      return nil unless notify_emails_to.present?

      if notify_emails_to.split(",").count > MAX_SHARE_BY_EMAILS
        errors.add(:base, _("You can share this push with up to %{count} email(s) including previous recipients") % {count: MAX_SHARE_BY_EMAILS})
      end

      unless Settings.mail.smtp_address.present?
        errors.add(:notify_emails_to, _("is using emails, but sending emails feature is not enabled"))
      end
    end
  end
end
