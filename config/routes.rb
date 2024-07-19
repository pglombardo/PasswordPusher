# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"} if ENV.key?("PWPUSH_COM")

  if Settings.enable_logins
    authenticated :user, ->(u) { u.admin? } do
      namespace :admin do
        resources :file_pushes
        resources :passwords
        resources :urls
        resources :users
        resources :views

        root to: "users#index"
      end
    end
  end

  apipie
  devise_for :users, skip: :registrations, controllers: {
    sessions: "users/sessions",
    passwords: "users/passwords",
    unlocks: "users/unlocks",
    confirmations: "users/confirmations"
  }

  allowed_reg_routes = if Settings.disable_signups
    %i[edit update]
  else
    %i[new create edit update]
  end

  devise_scope :user do
    resource :registration,
      only: allowed_reg_routes,
      path: "users",
      path_names: {new: "sign_up"},
      controller: "users/registrations",
      as: :user_registration do
      get :cancel
      get :token
      delete :token, action: :regen_token
    end
  end

  resources :p, controller: :passwords, as: :passwords, except: %i[index edit update] do
    get "preview", on: :member
    get "print_preview", on: :member
    get "passphrase", on: :member
    post "access", on: :member
    get "r", on: :member, as: "preliminary", action: "preliminary"
    get "audit", on: :member
    get "active", on: :collection
    get "expired", on: :collection
  end

  # File pushes only enabled when logins are enabled.
  if Settings.enable_logins && Settings.enable_file_pushes
    resources :f, controller: :file_pushes, as: :file_pushes, except: %i[index edit update] do
      get "preview", on: :member
      get "print_preview", on: :member
      get "passphrase", on: :member
      post "access", on: :member
      get "r", on: :member, as: "preliminary", action: "preliminary"
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end

  # URL based pushes can only enabled when logins are enabled.
  if Settings.enable_logins && Settings.enable_url_pushes
    resources :r, controller: :urls, as: :urls, except: %i[index edit update] do
      get "preview", on: :member
      get "print_preview", on: :member
      get "passphrase", on: :member
      post "access", on: :member
      get "r", on: :member, as: "preliminary", action: "preliminary"
      get "audit", on: :member
      get "active", on: :collection
      get "expired", on: :collection
    end
  end

  get "/pages/*id" => "pages#show", :as => :page, :format => false
  resources :feedbacks, only: %i[new create]

  draw :legacy_devise
  draw :legacy_feedbacks
  draw :legacy_pages
  draw :legacy_pushes

  root to: "passwords#new"
end
