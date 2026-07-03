constraints(format: :json) do
  namespace :api, defaults: {format: :json} do
    namespace :v2, defaults: {format: :json} do
      get :version, to: "version#show"

      resources :pushes, except: %i[new index edit update] do
        get "preview", on: :member
        get "audit", on: :member
        get "active", on: :collection
        get "expired", on: :collection
        post "notify_by_email", on: :member
      end
    end
  end

  namespace :api, defaults: {format: :json} do
    namespace :v1, defaults: {format: :json} do
      get :version, to: "version#show"
    end
  end

  resources :p, controller: "api/v1/pushes", as: :passwords, except: %i[new index edit update] do
    get "preview", on: :member
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end

  resources :p, controller: "api/v1/pushes", as: :json_pushes, except: %i[new index edit update] do
    get "preview", on: :member
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end

  if Settings.enable_file_pushes
    resources :f, controller: "api/v1/pushes", as: :file_pushes, except: %i[new index edit update] do
      get "preview", on: :member
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end

  if Settings.enable_url_pushes
    resources :r, controller: "api/v1/pushes", as: :urls, except: %i[new index edit update] do
      get "preview", on: :member
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end
end

# APIv2 Documentation
constraints(format: :html) do
  get "/help/api", to: "pages#api", as: :help_api
end

# Legacy APIv1 Documentation - redirect to https://docs.pwpush.com/docs/api-v1/
constraints(format: :html) do
  get "/api", to: redirect("https://docs.pwpush.com/docs/api-v1/"), as: :help_api_v1
end
