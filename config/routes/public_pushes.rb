# File pushes redirects - with query string preservation
get "/f/:url_token", to: redirect(path: "/p/%{url_token}", status: 301)
get "/f/:url_token/r", to: redirect(path: "/p/%{url_token}/r", status: 301)
get "/f/:url_token/passphrase", to: redirect(path: "/p/%{url_token}/passphrase", status: 301)

# URL pushes redirects - with query string preservation
get "/r/:url_token", to: redirect(path: "/p/%{url_token}", status: 301)
get "/r/:url_token/r", to: redirect(path: "/p/%{url_token}/r", status: 301)
get "/r/:url_token/passphrase", to: redirect(path: "/p/%{url_token}/passphrase", status: 301)

resources :p, controller: :pushes, as: :pushes, except: %i[edit update new create destroy] do
  get "passphrase", on: :member
  post "access", on: :member
  get "r", on: :member, as: "preliminary", action: "preliminary"
  delete "expire", on: :member
end
