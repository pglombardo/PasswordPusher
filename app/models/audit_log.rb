# frozen_string_literal: true

class AuditLog < ApplicationRecord
  MAX_AUDIT_LOGS_PER_PUSH_OR_PULL = 2000

  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view, :edit, :creation_email_send], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  has_one :notify_by_email, dependent: :destroy

  with_options on: :create, if: :creation_email_send? do |create|
    create.before_validation :build_associated_notify_by_email

    create.validates :user, presence: true
  end

  after_create_commit :record_prometheus_metrics

  def subject_name
    user&.email || "❓"
  end

  private

  def record_prometheus_metrics
    return unless Pwpush::Metrics.enabled?

    if creation?
      Pwpush::Metrics.increment(
        :pushes_created,
        labels: {kind: push.kind, authenticated: user.present?}
      )
      record_file_metrics if push.file?
    elsif %w[view failed_view expire failed_passphrase admin_view owner_view].include?(kind)
      Pwpush::Metrics.increment(
        :retrievals,
        labels: {kind: push.kind, event: kind}
      )
    end
  rescue => error
    Rails.logger.debug { "Prometheus audit metric failed: #{error.class}: #{error.message}" }
  end

  def record_file_metrics
    files = push.files.attachments.includes(:blob)
    Pwpush::Metrics.increment(:uploaded_files, value: files.size)
    Pwpush::Metrics.increment(:uploaded_file_bytes, value: files.sum { |file| file.blob.byte_size })
  end

  def build_associated_notify_by_email
    build_notify_by_email(
      recipients: push.notify_by_email_recipients,
      locale: push.notify_by_email_locale
    )
  end
end
