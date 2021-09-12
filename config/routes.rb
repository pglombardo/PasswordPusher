Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks',
    confirmations: 'users/confirmations'
  }

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
  root to: 'passwords#new'
end
