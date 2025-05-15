if Settings.enable_logins
  authenticated :user, ->(u) { u.admin? } do
    namespace :admin do
      resources :pushes
      resources :users
      resources :views

      root to: "users#index"
    end
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end
end
