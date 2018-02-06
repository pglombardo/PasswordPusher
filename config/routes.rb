PasswordPusher::Application.routes.draw do
  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  resources :c, :controller => :commands, :as => :commands, :allow => [ :create ]
  root :to => 'passwords#new'
end
