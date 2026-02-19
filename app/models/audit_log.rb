# frozen_string_literal: true

class AuditLog < ApplicationRecord
  MAX_AUDIT_LOGS_PER_PUSH_OR_PULL = 300

  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view, :edit], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  def subject_name
    user&.email || "❓"
  end
end
