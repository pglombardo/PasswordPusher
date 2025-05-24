resources :p, controller: :pushes, as: :pushes, except: %i[edit update new create destroy] do
  # get "preview", on: :member
  # get "print_preview", on: :member
  get "passphrase", on: :member
  post "access", on: :member
  get "r", on: :member, as: "preliminary", action: "preliminary"
  delete "expire", on: :member
  # get "audit", on: :member
  # get "active", on: :collection
  # get "expired", on: :collection
end
