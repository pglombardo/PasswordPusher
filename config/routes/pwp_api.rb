constraints(format: :json) do
  namespace :api do
    namespace :v1 do
      get :version, to: "version#show"
    end
  end

  resources :p, controller: "api/v1/pushes", as: :passwords, except: %i[new index edit update] do
    get "preview", on: :member
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end

  # File pushes only enabled when logins are enabled.
  if Settings.enable_logins && Settings.enable_file_pushes
    resources :f, controller: "api/v1/pushes", as: :file_pushes, except: %i[new index edit update] do
      get "preview", on: :member
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end

  # URL based pushes can only enabled when logins are enabled.
  if Settings.enable_logins && Settings.enable_url_pushes
    resources :r, controller: "api/v1/pushes", as: :urls, except: %i[new index edit update] do
      get "preview", on: :member
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end
end
