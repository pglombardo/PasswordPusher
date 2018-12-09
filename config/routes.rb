PasswordPusher::Application.routes.draw do
  devise_for :users
  scope :users do
    get 'pwds', controller: :users, action: :passwords
    get 'views', controller: :views, action: :index
    get 'views/:id', controller: :views, action: :show, as: 'show_view'
  end
  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  resources :c, :controller => :commands, :as => :commands, :allow => [ :create ]
  get '/slack_direct_install', to: redirect("https://slack.com/oauth/authorize?client_id=#{SLACK_CLIENT_ID}&scope=commands", status: 302)
  root :to => 'passwords#new'
end
