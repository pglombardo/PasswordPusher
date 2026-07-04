# frozen_string_literal: true

class NotifyByEmail < ApplicationRecord
  # audit_log_id is readonly because related audit_log is strongly coupled to notify_by_email record.
  attr_readonly :recipients, :recipients_count, :locale, :audit_log_id

  enum :status, [:pending, :processing, :completed, :partially_failed, :failed], validate: true

  before_create :set_recipients_count

  after_create :increment_email_sent_count
  after_create_commit :send_notify_by_email

  belongs_to :audit_log

  has_one :push, through: :audit_log
  has_one :user, through: :audit_log

  has_encrypted :recipients, :locale, :successful_sends, :error_message

  def increment_email_sent_count
    # Reset count if it's a new day
    if user.email_sent_count_reset_at.nil? || user.email_sent_count_reset_at.before?(Time.current.beginning_of_day)
      user.update(
        email_sent_count: recipients_count,
        email_sent_count_reset_at: Time.current
      )
    else
      user.update(email_sent_count: user.email_sent_count + recipients_count)
    end
  end

  def assign_fields_to_push
    return unless persisted?

    push.notify_by_email_recipients = recipients
    push.notify_by_email_locale = locale
    push.notify_by_email_creator = user
    push.notify_by_email_skip_limit_validation = true
    push.notify_by_email_required = true
  end

  private

  def set_recipients_count
    self.recipients_count = recipients.split(",").count
  end

  def send_notify_by_email
    SendNotifyByEmailJob.perform_later(id)
  end
end
