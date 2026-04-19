# frozen_string_literal: true

class ShareByEmail < ApplicationRecord
  attr_readonly :locale
  attr_readonly :recipients

  enum :status, {pending: 0, processing: 1, completed: 2, partially_failed: 3, fully_failed: 4}

  belongs_to :audit_log

  has_one :push, through: :audit_log

  has_encrypted :locale, :recipients, :successful_sends

  validates :recipients, presence: true, multiple_emails: true
  validates :locale, inclusion: {in: I18n.available_locales.map(&:to_s)}, allow_blank: true, allow_nil: true
end
