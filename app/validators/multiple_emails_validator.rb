# frozen_string_literal: true

# Validates comma-separated email addresses: format, max 5, no duplicates.
class MultipleEmailsValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  MAX_EMAILS = 5

  def validate_each(record, attribute, value)
    return if value.blank?

    emails = Pwpush::NotifyEmailsTo.parse_emails(value)

    if emails.size > MAX_EMAILS
      record.errors.add(:base, I18n._("You can enter at most %{count} email addresses") % {count: MAX_EMAILS})
    end

    if emails.size != emails.map(&:downcase).uniq.size
      record.errors.add(:base, I18n._("Duplicate email addresses are not allowed"))
    end

    invalid = emails.reject { |e| e.match?(EMAIL_REGEX) }
    unless invalid.empty?
      record.errors.add(:base, I18n._("%{list} are invalid email addresses") % {list: invalid.join(", ")})
    end
  end
end
