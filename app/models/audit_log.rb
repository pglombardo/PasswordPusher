# frozen_string_literal: true

class AuditLog < ApplicationRecord
  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase]
  
  validates :kind, inclusion: { in: self.kinds, message: "%{value} is not a valid audit log type" }

  belongs_to :push
  belongs_to :user, optional: true

  def subject_name
    user&.email || "❓"
  end
end
