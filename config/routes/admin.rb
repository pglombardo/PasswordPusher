authenticated :user, lambda { |u| u.admin? } do
  get "/admin", to: "admin#index", as: :admin_root

  namespace :admin do
    resources :users, only: [:index, :destroy] do
      member do
        patch :promote
        patch :revoke
      end
    end

    resource :custom_css, only: [:edit, :update], controller: "custom_css"
  end

  mount MissionControl::Jobs::Engine, at: "/admin/jobs" if defined?(::MissionControl::Jobs::Engine)
end
