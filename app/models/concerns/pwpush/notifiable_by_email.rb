# frozen_string_literal: true

module Pwpush
  module NotifiableByEmail
    extend ActiveSupport::Concern
    MAX_NOTIFY_BY_EMAILS = 5

    included do
      attr_accessor :notify_by_email_recipients, :notify_by_email_locale, :notify_by_email_required, :notify_by_email_creator

      has_many :notify_by_emails_audit_logs, -> { where(kind: :creation_email_send) }, class_name: "AuditLog", dependent: :destroy
      has_many :notify_by_emails, through: :notify_by_emails_audit_logs

      validate :notify_by_email_availability, if: -> { notify_by_email_recipients.present? }
      validates :notify_by_email_recipients, multiple_emails: {max_emails: MAX_NOTIFY_BY_EMAILS}
      validates :notify_by_email_recipients, presence: true, if: :notify_by_email_required
      validates :notify_by_email_locale, allow_blank: true, allow_nil: true, inclusion: {in: I18n.available_locales.map(&:to_s)}
      validate :notify_by_email_limit

      def notify_by_email_allowed?(cur_user)
        Settings.notify_by_email_available? && cur_user.present? && (!persisted? || (cur_user == user))
      end
    end

    private

    def notify_by_email_limit
      return if notify_by_email_recipients.blank?

      new_count = notify_by_email_recipients.split(",").count
      remaining = MAX_NOTIFY_BY_EMAILS - total_notify_by_emails_count

      if new_count > remaining
        if notify_by_emails.any?
          errors.add(:base, _("You can notify up to %{count} email(s) and you have already sent emails to %{total_count} recipients") % {count: MAX_NOTIFY_BY_EMAILS, total_count: total_notify_by_emails_count})
        else
          errors.add(:base, _("You can notify up to %{count} email(s)") % {count: MAX_NOTIFY_BY_EMAILS})
        end
      end
    end

    def total_notify_by_emails_count
      return 0 if notify_by_emails.none?

      notify_by_emails.sum(&:recipients_count)
    end

    def notify_by_email_availability
      unless Settings.notify_by_email_available?
        errors.add(:base, _("Notifying by email is not available"))

        return
      end

      notify_by_email_custom_validations

      unless notify_by_email_creator.present?
        errors.add(:base, _("Notifying by email is not allowed for unknown users"))

        return
      end

      unless notify_by_email_creator == user
        errors.add(:base, _("Notifying by email is allowed for only owners"))

        return
      end

      if notify_by_email_creator.email_limit_reached?
        errors.add(:base, _("The maximum number of emails has been reached for today"))
      end
    end

    # Override this method in the model to add custom validations
    def notify_by_email_custom_validations
      nil
    end
  end
end
