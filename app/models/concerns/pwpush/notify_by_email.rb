# frozen_string_literal: true

module Pwpush
  module NotifyByEmail
    extend ActiveSupport::Concern
    MAX_NOTIFY_BY_EMAILS = 5

    included do
      attr_accessor :notify_by_email_locale
      attr_accessor :notify_by_email_recipients

      has_many :notify_by_emails_audit_logs, -> { where(kind: :creation_email_send) }, class_name: "AuditLog", dependent: :destroy
      has_many :notify_by_emails, through: :notify_by_emails_audit_logs

      validates :notify_by_email_locale, inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true, allow_nil: true

      validates :notify_by_email_recipients, multiple_emails: {max_emails: MAX_NOTIFY_BY_EMAILS}
      validate :email_limit, on: :update
    end

    private

    def total_notify_by_emails_count
      notify_by_emails.sum { |notify_by_email| notify_by_email.recipients.split(",").count }
    end

    def email_limit
      return if notify_by_email_recipients.blank?

      if total_notify_by_emails_count + notify_by_email_recipients.split(",").count > MAX_NOTIFY_BY_EMAILS
        errors.add(:base, _("You can notify up to %{count} email(s) for this push and you have already sent emails to %{total_count} recipients") % {count: MAX_NOTIFY_BY_EMAILS, total_count: total_notify_by_emails_count})
      end
    end
  end
end
