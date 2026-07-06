# frozen_string_literal: true

module Pwpush
  module NotifiableByEmail
    extend ActiveSupport::Concern
    MAX_NOTIFY_BY_EMAILS = 5

    NOTIFY_BY_EMAIL_HUMAN_ATTRIBUTE_NAMES = {
      notify_emails_to: "Recipient emails",
      notify_emails_to_locale: "Notification language"
    }.freeze

    included do
      attr_accessor :notify_emails_to, :notify_emails_to_locale, :notify_emails_to_required, :notify_by_email_creator, :notify_by_email_skip_limit_validation, :notify_by_email_recipients, :notify_by_email_locale

      has_many :notify_by_emails_audit_logs, -> { where(kind: :creation_email_send) }, class_name: "AuditLog", dependent: :destroy
      has_many :notify_by_emails, through: :notify_by_emails_audit_logs

      validates :notify_emails_to, multiple_emails: true
      validates :notify_emails_to_locale, allow_blank: true, inclusion: {in: I18n.available_locales.map(&:to_s)}

      validate :validate_notify_by_email

      after_validation :assign_notify_by_email_fields

      def notify_by_email_allowed_for?(cur_user)
        notify_by_email_available? && cur_user.present? && (!persisted? || (cur_user == user))
      end

      def notify_by_email_available?
        Settings.notify_by_email_available?
      end
    end

    class_methods do
      def human_attribute_name(attribute, options = {})
        name = NOTIFY_BY_EMAIL_HUMAN_ATTRIBUTE_NAMES[attribute.to_sym]
        name ? _(name) : super
      end
    end

    private

    def validate_notify_by_email
      validate_notify_emails_to_presence if notify_emails_to_required
      return unless notify_emails_to.present? || notify_emails_to_locale.present?

      validate_notify_by_email_availability
      validate_notify_by_email_limit unless notify_by_email_skip_limit_validation
    end

    def validate_notify_emails_to_presence
      unless notify_emails_to.present?
        errors.add(:notify_emails_to, :blank)
      end
    end

    def validate_notify_by_email_availability
      unless notify_by_email_available?
        errors.add(:notify_emails_to, _("are not available")) if notify_emails_to.present?
        errors.add(:notify_emails_to_locale, _("is not available")) if notify_emails_to_locale.present?
        errors.add(:base, _("Notify by email feature is not enabled"))

        return
      end

      notify_by_email_custom_validations

      unless notify_by_email_creator.present?
        errors.add(:notify_emails_to, _("are not allowed for unknown users")) if notify_emails_to.present?
        errors.add(:notify_emails_to_locale, _("is not allowed for unknown users")) if notify_emails_to_locale.present?

        return
      end

      unless notify_by_email_creator == user
        errors.add(:notify_emails_to, _("are allowed for only owners")) if notify_emails_to.present?
        errors.add(:notify_emails_to_locale, _("is allowed for only owners")) if notify_emails_to_locale.present?

        return
      end

      if notify_by_email_creator.email_limit_reached?
        errors.add(:base, _("The maximum number of emails has been reached for today"))
      end
    end

    def validate_notify_by_email_limit
      return if notify_emails_to.blank?

      # This validation is done by multiple_emails validator
      return if notify_by_emails.none?

      new_count = notify_emails_to.split(",").count
      remaining = MAX_NOTIFY_BY_EMAILS - total_emails_count

      if new_count > remaining
        errors.add(:base, _("You can notify up to %{count} email(s) and you have already sent emails to %{total_count} recipients") % {count: MAX_NOTIFY_BY_EMAILS, total_count: total_emails_count})
      end
    end

    def total_emails_count
      return 0 if notify_by_emails.none?

      notify_by_emails.sum(&:recipients_count)
    end

    def assign_notify_by_email_fields
      self.notify_by_email_recipients = notify_emails_to if notify_emails_to.present?
      self.notify_by_email_locale = notify_emails_to_locale if notify_emails_to_locale.present?
    end

    # Override this method in the model to add custom validations
    def notify_by_email_custom_validations
      nil
    end
  end
end
