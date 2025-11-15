class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email, index: true
  attribute :created_at, form: false
  attribute :confirmed_at, index: true
  attribute :last_sign_in_at, index: true
  # attribute :encrypted_password, index: false, form: false
  attribute :reset_password_token, index: false, form: false
  attribute :reset_password_sent_at, index: false
  # attribute :remember_created_at, index: false
  attribute :sign_in_count, form: false
  attribute :current_sign_in_at, index: false
  attribute :current_sign_in_ip, index: false
  attribute :last_sign_in_ip, index: false
  attribute :updated_at, form: false
  # attribute :admin, index: true
  attribute :failed_attempts, index: false
  # attribute :unlock_token, index: false, form: false
  attribute :locked_at, index: false
  # attribute :confirmation_token, index: false, form: false
  attribute :confirmation_sent_at, index: false
  # attribute :unconfirmed_email, index: false
  attribute :authentication_token, index: false, form: false
  attribute :preferred_language, index: false

  # Associations
  attribute :pushes

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    record.email
  end

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
