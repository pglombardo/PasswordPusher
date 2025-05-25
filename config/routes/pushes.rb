constraints(format: :html) do
  get "/f/:url_token", to: redirect("/p/%{url_token}")
  get "/f/:url_token/r", to: redirect("/p/%{url_token}/r")
  get "/f/:url_token/passphrase", to: redirect("/p/%{url_token}/passphrase")

  get "/r/:url_token", to: redirect("/p/%{url_token}")
  get "/r/:url_token/r", to: redirect("/p/%{url_token}/r")
  get "/r/:url_token/passphrase", to: redirect("/p/%{url_token}/passphrase")
  
  resources :p, controller: :pushes, as: :pushes, except: %i[edit update destroy] do
    get "preview", on: :member
    get "print_preview", on: :member
    get "passphrase", on: :member
    post "access", on: :member
    get "r", on: :member, as: "preliminary", action: "preliminary"
    delete "expire", on: :member
    get "audit", on: :member
  end
end
