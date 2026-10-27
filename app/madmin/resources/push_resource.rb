class PushResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :url_token, index: true
  attribute :kind, index: true
  attribute :expire_after_days
  attribute :expire_after_views
  attribute :expired, index: true
  attribute :deletable_by_viewer
  attribute :retrieval_step
  attribute :expired_on
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :user
  attribute :audit_logs

  # Add scopes to easily filter records
  # scope :published

  # Audit rows for this push. Data Explorer is admin-only; the owner audit page is not.
  member_action collection: true do |push|
    link_to _("Audit Log"),
      madmin_audit_logs_path(filters: [{column: "push_id", operator: "eq", value: push.id}]),
      class: "btn btn-outline-secondary"
  end

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    record.url_token
  end

  # Use url_token for lookups instead of id
  def self.model_find(id)
    model.find_by!(url_token: id)
  end

  # Customize the default sort column and direction.
  def self.default_sort_column = "created_at"

  def self.default_sort_direction = "desc"
end
