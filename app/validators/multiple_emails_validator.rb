# frozen_string_literal: true

# Copyright (c) 2025 Apnotic, LLC. All rights reserved.
# This software is proprietary and confidential.
# Unauthorized copying, distribution, or use is strictly prohibited.

class MultipleEmailsValidator < ActiveModel::EachValidator
  # Email regex pattern matching the one used in app/models/feedback.rb:8
  EMAIL_REGEX = /\A([\w.%+-]+)@([\w-]+\.)+(\w{2,})\z/i

  # Validates comma-separated emails with count and format validation
  #
  # @param record [ActiveRecord::Base] The model instance being validated
  # @param attribute [Symbol] The attribute being validated
  # @param value [String] The comma-separated email string
  # @return [void]
  def validate_each(record, attribute, value)
    return if value.blank?

    max_emails = options[:max_emails] || 5
    emails = value.split(",").map(&:strip)

    if emails.any?(&:blank?)
      record.errors.add(attribute, I18n._("has commas used in the wrong way"))
    end

    if value.end_with?(",")
      record.errors.add(attribute, I18n._("has commas used in the wrong way"))
    end

    if emails.count != emails.uniq.count
      record.errors.add(attribute, I18n._("contains duplicate emails"))
    end

    if emails.count > max_emails
      (max_emails == 1) ? record.errors.add(attribute, I18n._("contains more than 1 email")) : record.errors.add(attribute, I18n._("contains more than %{count} emails") % {count: max_emails})
    end

    unless emails.reject(&:blank?).all? { |email| email.match?(EMAIL_REGEX) }
      record.errors.add(attribute, I18n._("contains invalid email(s)"))
    end
  end
end
