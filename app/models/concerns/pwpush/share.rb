# frozen_string_literal: true

module Pwpush
  module Share
    extend ActiveSupport::Concern
    MAX_SHARE_BY_EMAILS = 5

    included do
      attr_accessor :share_locale
      attr_accessor :share_recipients

      has_many :share_by_emails_audit_logs, -> { where(kind: :creation_email_send) }, class_name: "AuditLog", dependent: :destroy
      has_many :share_by_emails, through: :share_by_emails_audit_logs

      validates :share_locale, inclusion: {in: I18n.available_locales.map(&:to_s)},
        allow_blank: true, allow_nil: true

      validates :share_recipients, multiple_emails: {max_emails: MAX_SHARE_BY_EMAILS}
      validate :share_limit, on: :update
    end

    private

    def total_share_by_emails_count
      share_by_emails.sum { |share| share.recipients.split(",").count }
    end

    def share_limit
      return if share_recipients.blank?

      if total_share_by_emails_count + share_recipients.split(",").count > MAX_SHARE_BY_EMAILS
        errors.add(:base, _("You can share this push with up to %{count} email(s) and you have already sent emails to %{total_count} recipients") % {count: MAX_SHARE_BY_EMAILS, total_count: total_share_by_emails_count})
      end
    end
  end
end
