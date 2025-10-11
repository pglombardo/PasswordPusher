class SolidQueue::RecurringTaskResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :key
  attribute :schedule
  attribute :command
  attribute :class_name
  attribute :arguments
  attribute :queue_name
  attribute :priority
  attribute :static
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :recurring_executions

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
