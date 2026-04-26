# frozen_string_literal: true

class AuditLog < ApplicationRecord
  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view, :edit, :creation_email_send], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  has_one :notify_by_email, dependent: :destroy

  validate :user_matches_push_owner, if: -> { kind == "creation_email_send" }

  def subject_name
    user&.email || "❓"
  end

  private

  def user_matches_push_owner
    if user.blank?
      errors.add(:user, "must be present for creation email sends")
    end

    errors.add(:user, "must be the push owner for creation email sends") if user != push.user
  end
end
