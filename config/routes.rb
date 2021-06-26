Rails.application.routes.draw do
  resources :p, controller: :passwords, as: :passwords, except: %i[index edit update] do
    get 'preview', on: :member
    get 'r', on: :member, as: 'preliminary', action: 'preliminary'
  end
  resources :c, controller: :commands, as: :commands, allow: %i[create]
  get '/slack_direct_install', to: redirect("https://slack.com/oauth/authorize?client_id=#{SLACK_CLIENT_ID}&scope=commands", status: 302)
  root to: 'passwords#new'
end
