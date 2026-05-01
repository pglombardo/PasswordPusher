# frozen_string_literal: true

class NotifyByEmail < ApplicationRecord
  attr_readonly :recipients, :recipients_count, :locale

  enum :status, [:pending, :processing, :completed, :partially_failed, :fully_failed], validate: true

  before_create :set_recipients_count

  belongs_to :audit_log

  has_one :push, through: :audit_log
  has_encrypted :recipients, :locale, :successful_sends

  private

  def set_recipients_count
    self.recipients_count = recipients.split(",").count
  end
end
