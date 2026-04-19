# frozen_string_literal: true

class AuditLog < ApplicationRecord
  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view, :edit, :creation_email_send], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  has_one :share_by_email, dependent: :destroy

  def subject_name
    user&.email || "❓"
  end
end
