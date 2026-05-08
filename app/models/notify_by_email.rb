# frozen_string_literal: true

class NotifyByEmail < ApplicationRecord
  # audit_log_id is readonly because related audit_log is strongly coupled to notify_by_email record.
  attr_readonly :recipients, :recipients_count, :locale, :audit_log_id

  enum :status, [:pending, :processing, :completed, :partially_failed, :failed], validate: true

  before_create :set_recipients_count

  after_create_commit :send_notify_by_email
  after_create_commit :increment_notify_by_email_daily_usage

  belongs_to :audit_log

  has_one :push, through: :audit_log
  has_one :user, through: :audit_log

  has_encrypted :recipients, :locale, :successful_sends, :error_message

  def increment_notify_by_email_daily_usage
    recipients_count = recipients.split(",").count
    cache_key = "notify_by_email_daily_usage_#{user.id}_#{Time.current.beginning_of_day.to_i}"

    if Rails.cache.exist?(cache_key)
      Rails.cache.increment(cache_key, by: recipients_count)
    else
      Rails.cache.write(cache_key, recipients_count, expires_in: 1.day)
    end
  end

  private

  def set_recipients_count
    self.recipients_count = recipients.split(",").count
  end

  def send_notify_by_email
    SendNotifyByEmailJob.perform_later(id)
  end
end
