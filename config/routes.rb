PasswordPusher::Application.routes.draw do
  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  resources :c, :controller => :commands, :as => :commands, :allow => [ :create ]
  get '/slack_direct_install', to: redirect("https://slack.com/oauth/authorize?client_id=#{SLACK_CLIENT_ID}&scope=commands", status: 302)
  root :to => 'passwords#new'
end
