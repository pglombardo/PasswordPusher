resources :p, controller: :passwords, as: :passwords, except: %i[index edit update] do
  get "preview", on: :member
  get "print_preview", on: :member
  get "passphrase", on: :member
  post "access", on: :member
  get "r", on: :member, as: "preliminary", action: "preliminary"
  get "audit", on: :member
  get "active", on: :collection
  get "expired", on: :collection
end

# File pushes only enabled when logins are enabled.
if Settings.enable_logins && Settings.enable_file_pushes
  resources :f, controller: :file_pushes, as: :file_pushes, except: %i[index edit update] do
    get "preview", on: :member
    get "print_preview", on: :member
    get "passphrase", on: :member
    post "access", on: :member
    get "r", on: :member, as: "preliminary", action: "preliminary"
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end
end

# URL based pushes can only enabled when logins are enabled.
if Settings.enable_logins && Settings.enable_url_pushes
  resources :r, controller: :urls, as: :urls, except: %i[index edit update] do
    get "preview", on: :member
    get "print_preview", on: :member
    get "passphrase", on: :member
    post "access", on: :member
    get "r", on: :member, as: "preliminary", action: "preliminary"
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end
end
