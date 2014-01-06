PasswordPusher::Application.routes.draw do
  # mount RailsAdmin::Engine => '/power', :as => 'rails_admin'
  
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } do
    get "/login" => "devise/sessions#new"
    delete "/logout" => "devise/sessions#destroy"
    get "/register" => "devise/registrations#destroy"
  end

  resources :p, :controller => :passwords, :as => :passwords, :except => :index
  
  # Password Creator route
  # match '/p/:url_token/:admin_key' => 'passwords#details', :via => :get, :as => :password
  
  root :to => 'passwords#new'
  
  match 'pages/about' => 'high_voltage/pages#show', :id => 'about'
  
  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'errors#error_404'
  end
end
