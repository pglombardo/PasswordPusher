if Settings.enable_logins
  authenticated :user, lambda { |u| u.admin? } do
    get "/admin", to: "admin#index", as: :admin_root

    namespace :admin do
      resources :users, only: [:index] do
        member do
          patch :promote
          patch :revoke
        end
      end
    end

    if !(ENV.key?("PWP__NO_WORKER") || ENV.key?("PWP_PUBLIC_GATEWAY"))
      mount MissionControl::Jobs::Engine, at: "/admin/jobs" if defined?(::MissionControl::Jobs::Engine)
    end
  end
end
