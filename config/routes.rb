PasswordPusher::Application.routes.draw do
  
  mount RailsAdmin::Engine => '/power', :as => 'rails_admin'

  devise_for :users

  resources :passwords, :only => [ :new, :create, :show ] do
    resources :views, :only => [ :index, :show ]
  end
  
  match '/p/:url_token' => 'passwords#show'
  match '/p' => 'passwords#new'

  root :to => 'passwords#new'
  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
