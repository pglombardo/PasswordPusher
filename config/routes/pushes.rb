constraints(format: :html) do
  resources :p, controller: :pushes, as: :pushes, except: %i[edit update destroy] do
    get "preview", on: :member
    get "print_preview", on: :member
    get "passphrase", on: :member
    post "access", on: :member
    delete "expire", on: :member
    get "r", on: :member, as: "preliminary", action: "preliminary"
    get "audit", on: :member
  end
end
