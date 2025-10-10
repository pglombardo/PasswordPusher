class SolidQueue::BlockedExecutionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :queue_name
  attribute :priority
  attribute :concurrency_key
  attribute :expires_at
  attribute :created_at, form: false

  # Associations
  attribute :job
  attribute :semaphore

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
