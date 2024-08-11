if Settings.enable_logins
  authenticated :user, ->(u) { u.admin? } do
    namespace :admin do
      resources :file_pushes
      resources :passwords
      resources :urls
      resources :users
      resources :views

      root to: "users#index"
    end
  end
end
