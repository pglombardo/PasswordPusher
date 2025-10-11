class ActiveStorage::VariantRecordResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :variation, index: false, show: false
  attribute :variation_confirmation, index: false, show: false
  attribute :image, index: false

  # Associations
  attribute :blob

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
