class AuditLogResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :ip, index: true
  attribute :user_agent, index: true
  attribute :referrer, index: true
  attribute :kind, index: true
  attribute :updated_at, form: false
  # Used to filter this index from a push row. Hidden everywhere else.
  attribute :push_id, index: false, show: false, form: false

  # Associations
  attribute :push
  attribute :user
  attribute :notify_by_email

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
