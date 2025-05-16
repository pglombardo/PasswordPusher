# frozen_string_literal: true

class AuditLog < ApplicationRecord
  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :retrieve, :response, :close, :edit]

  belongs_to :push
  belongs_to :user, optional: true

  validates :kind, presence: true
end
