# frozen_string_literal: true

# Validates comma-separated email addresses: format, max 5, no duplicates.
class MultipleEmailsValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  MAX_EMAILS = 5

  def validate_each(record, attribute, value)
    return if value.blank?

    emails = value.to_s.split(",").map(&:strip).reject(&:blank?)

    if emails.size > MAX_EMAILS
      record.errors.add(attribute, _("%{count} email addresses are allowed", count: MAX_EMAILS))
    end

    if emails.size != emails.uniq.size
      record.errors.add(attribute, _("Duplicate email addresses are not allowed"))
    end

    invalid = emails.reject { |e| e.match?(EMAIL_REGEX) }
    if invalid.empty?
      record.errors.add(attribute, _("%{list} are invalid email addresses", list: invalid.join(", ")))
    end
  end
end
