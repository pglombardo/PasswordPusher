PasswordPusher::Application.routes.draw do
  
#  post "api/create"
#  get "api/generate"
#  get "api/list"
#  get "api/config"

  mount RailsAdmin::Engine => '/power', :as => 'rails_admin'

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } do
    get "/login" => "devise/sessions#new"
    delete "/logout" => "devise/sessions#destroy"
    get "/register" => "devise/registrations#destroy"
  end

  resources :passwords, :only => [ :new, :create ] do
    resources :views, :only => [ :index, :show ]
  end
  
  # Password paths
  match '/p/:url_token' => 'passwords#show'
  match '/p' => 'passwords#new'
  
  # The user dashboard
#  match '/d' => 'dashboard#index'

  root :to => 'passwords#new'
end
