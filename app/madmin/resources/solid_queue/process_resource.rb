class SolidQueue::ProcessResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :kind
  attribute :last_heartbeat_at
  attribute :pid
  attribute :hostname
  attribute :metadata
  attribute :created_at, form: false
  attribute :name

  # Associations
  attribute :claimed_executions
  attribute :supervisor
  attribute :supervisees

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
