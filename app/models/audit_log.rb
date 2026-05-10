# frozen_string_literal: true

class AuditLog < ApplicationRecord
  MAX_AUDIT_LOGS_PER_PUSH_OR_PULL = 2000

  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view, :edit, :creation_email_send], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  has_one :notify_by_email, dependent: :destroy

  validates :user, presence: true, if: :creation_email_send?
  before_create :build_associated_notify_by_email, if: :creation_email_send?

  def subject_name
    user&.email || "❓"
  end

  private

  def build_associated_notify_by_email
    build_notify_by_email(
      recipients: push.notify_by_email_recipients,
      locale: push.notify_by_email_locale
    )
  end
end
