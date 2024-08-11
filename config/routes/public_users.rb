# devise_for :users, skip: :registrations, controllers: {
devise_for :users, only: :sessions, controllers: {
  sessions: "users/sessions"
}

# allowed_reg_routes = if Settings.disable_signups
#   %i[edit update]
# else
#   %i[new create edit update]
# end

devise_scope :user do
  resource :registration, only: [], path: "users"
end
