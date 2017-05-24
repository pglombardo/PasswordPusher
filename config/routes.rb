PasswordPusher::Application.routes.draw do
  resources :p, :controller => :passwords, :as => :passwords, :except => [ :index, :edit, :update ]
  root :to => 'passwords#new'
  match 'pages/about' => 'high_voltage/pages#show', :id => 'about'
  match 'pages/faq' => 'high_voltage/pages#show', :id => 'faq'

  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'errors#error_404'
  end
end
