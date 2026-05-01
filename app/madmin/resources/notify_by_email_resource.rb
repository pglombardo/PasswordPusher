class NotifyByEmailResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :recipients
  attribute :locale
  attribute :status
  attribute :proceed_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :audit_log
  attribute :push
end
