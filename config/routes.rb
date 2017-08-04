PasswordPusher::Application.routes.draw do
  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  root :to => 'passwords#new'
end
