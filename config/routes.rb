Rails.application.routes.draw do
  localized do
    devise_for :users, skip: :registrations, controllers: {
      sessions: 'users/sessions',
      passwords: 'users/passwords',
      unlocks: 'users/unlocks',
      confirmations: 'users/confirmations'
    }

    devise_scope :user do
      resource  :registration,
                only: %i[new create edit update],
                path: 'users',
                path_names: { new: 'sign_up' },
                controller: 'users/registrations',
                as: :user_registration do
                  get :cancel
                end
    end

    get '/d/active' => 'dashboard#active', as: :dashboard_active
    get '/d/expired' => 'dashboard#expired', as: :dashboard_expired

    resources :p, controller: :passwords, as: :passwords, except: %i[index edit update] do
      get 'preview', on: :member
      get 'r', on: :member, as: 'preliminary', action: 'preliminary'
      get 'audit', on: :member
    end

    resources :c, controller: :commands, as: :commands, allow: %i[create]
    get '/slack_direct_install', to: redirect("https://slack.com/oauth/authorize?client_id=#{SLACK_CLIENT_ID}&scope=commands", status: 302)
    get '/pages/*id' => 'pages#show', as: :page, format: false
    resources :feedbacks, only: %i[new create]
    root to: 'passwords#new'
  end
end
