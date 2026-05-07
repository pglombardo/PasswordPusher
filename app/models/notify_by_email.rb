# frozen_string_literal: true

class NotifyByEmail < ApplicationRecord
  # audit_log_id is readonly because related audit_log is strongly coupled to notify_by_email record.
  attr_readonly :recipients, :recipients_count, :locale, :audit_log_id

  enum :status, [:pending, :processing, :completed, :partially_failed, :failed], validate: true

  before_create :set_recipients_count

  belongs_to :audit_log

  has_one :push, through: :audit_log
  has_encrypted :recipients, :locale, :successful_sends, :error_message

  after_create_commit :send_notify_by_email

  private

  def set_recipients_count
    self.recipients_count = recipients.split(",").count
  end

  def send_notify_by_email
    SendNotifyByEmailJob.perform_later(id)
  end
end
