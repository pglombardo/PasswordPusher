# frozen_string_literal: true

class NotifyByEmail < ApplicationRecord
  attr_readonly :recipients, :recipients_count, :locale

  enum :status, {pending: 0, processing: 1, completed: 2, partially_failed: 3, fully_failed: 4}

  before_save :set_recipients_count

  belongs_to :audit_log, dependent: :destroy

  has_one :push, through: :audit_log
  has_encrypted :recipients, :locale, :successful_sends

  private

  def set_recipients_count
    self.recipients_count = recipients.split(",").count
  end
end
