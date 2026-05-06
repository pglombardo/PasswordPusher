class NotifyByEmailResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :recipients, form: false
  attribute :locale, form: false
  attribute :status
  attribute :error_message
  attribute :proceed_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :audit_log, form: false
  attribute :push, form: false
end
