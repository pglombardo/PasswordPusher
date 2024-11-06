allowed_reg_routes = if Settings.disable_signups
  %i[edit update]
else
  %i[new create edit update]
end

devise_for :users, skip: :registrations, controllers: {
  sessions: "users/sessions",
  passwords: "users/passwords",
  unlocks: "users/unlocks",
  confirmations: "users/confirmations",
  registrations: "users/registrations"
}

devise_scope :user do
  resource :registration,
    only: allowed_reg_routes,
    path: "users",
    path_names: {new: "sign_up"},
    controller: "users/registrations",
    as: :user_registration do
      get :cancel
      get :token
      delete :token, action: :regen_token
    end
end
