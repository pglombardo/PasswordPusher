PasswordPusher::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  root :to => 'passwords#new'
  match 'pages/about' => 'high_voltage/pages#show', :id => 'about'

  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'errors#error_404'
  end
end
