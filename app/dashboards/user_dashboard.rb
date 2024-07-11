require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    admin: Field::Boolean,
    authentication_token: Field::String,
    confirmation_sent_at: Field::DateTime.with_options(timezone: Settings.timezone),
    confirmation_token: Field::String,
    confirmed_at: Field::DateTime.with_options(timezone: Settings.timezone),
    current_sign_in_at: Field::DateTime.with_options(timezone: Settings.timezone),
    current_sign_in_ip: Field::String,
    email: Field::String,
    encrypted_password: Field::String,
    password: Field::String.with_options(searchable: false),
    password_confirmation: Field::String.with_options(searchable: false),
    failed_attempts: Field::Number,
    file_pushes: Field::HasMany,
    last_sign_in_at: Field::DateTime.with_options(timezone: Settings.timezone),
    last_sign_in_ip: Field::String,
    locked_at: Field::DateTime.with_options(timezone: Settings.timezone),
    passwords: Field::HasMany,
    remember_created_at: Field::DateTime.with_options(timezone: Settings.timezone),
    reset_password_sent_at: Field::DateTime.with_options(timezone: Settings.timezone),
    reset_password_token: Field::String,
    sign_in_count: Field::Number,
    unconfirmed_email: Field::String,
    unlock_token: Field::String,
    urls: Field::HasMany,
    created_at: Field::DateTime.with_options(timezone: Settings.timezone),
    updated_at: Field::DateTime.with_options(timezone: Settings.timezone)
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    email
    created_at
    confirmed_at
    sign_in_count
    admin
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    admin
    authentication_token
    confirmation_sent_at
    confirmation_token
    confirmed_at
    current_sign_in_at
    current_sign_in_ip
    email
    encrypted_password
    failed_attempts
    last_sign_in_at
    last_sign_in_ip
    locked_at
    remember_created_at
    reset_password_sent_at
    reset_password_token
    sign_in_count
    unconfirmed_email
    unlock_token
    created_at
    updated_at
    passwords
    file_pushes
    urls
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    admin
    authentication_token
    confirmation_sent_at
    confirmation_token
    confirmed_at
    current_sign_in_at
    current_sign_in_ip
    email
    password
    failed_attempts
    file_pushes
    last_sign_in_at
    last_sign_in_ip
    locked_at
    passwords
    remember_created_at
    reset_password_sent_at
    reset_password_token
    sign_in_count
    unconfirmed_email
    unlock_token
    urls
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   "User ##{user.id}"
  # end
  def display_resource(user)
    user.email.to_s
  end
end
