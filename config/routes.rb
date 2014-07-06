PasswordPusher::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  resources :p, :controller => :passwords, :as => :passwords, :except => :index
  
  # Password Creator route
  # match '/p/:url_token/:admin_key' => 'passwords#details', :via => :get, :as => :password
  
  root :to => 'passwords#new'
  
  get 'pages/about' => 'high_voltage/pages#show', :id => 'about'
  
  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'errors#error_404'
  end
end
