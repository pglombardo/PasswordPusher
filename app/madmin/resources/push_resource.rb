class PushResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :kind
  attribute :expire_after_days
  attribute :expire_after_views
  attribute :expired
  attribute :url_token
  attribute :deletable_by_viewer
  attribute :retrieval_step
  attribute :expired_on
  attribute :payload_ciphertext
  attribute :note_ciphertext
  attribute :passphrase_ciphertext
  attribute :name
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :payload, index: false
  attribute :note, index: false
  attribute :passphrase, index: false
  attribute :files, index: false

  # Associations
  attribute :user
  attribute :audit_logs

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
