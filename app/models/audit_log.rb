# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :push
  belongs_to :user, optional: true
end
