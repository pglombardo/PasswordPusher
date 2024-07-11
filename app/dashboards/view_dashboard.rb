require "administrate/base_dashboard"

class ViewDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    file_push: Field::BelongsTo,
    ip: Field::String,
    kind: Field::Number,
    password: Field::BelongsTo,
    referrer: Field::String,
    successful: Field::Boolean,
    url: Field::BelongsTo,
    user: Field::BelongsTo,
    user_agent: Field::String,
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
    ip
    user_agent
    created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    file_push
    ip
    kind
    password
    referrer
    successful
    url
    user
    user_agent
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    file_push
    ip
    kind
    password
    referrer
    successful
    url
    user
    user_agent
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

  # Overwrite this method to customize how views are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(view)
  #   "View ##{view.id}"
  # end
end
