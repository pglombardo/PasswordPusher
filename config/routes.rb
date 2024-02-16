# frozen_string_literal: true

Rails.application.routes.draw do
  routes_config = proc do
    match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"} if ENV.key?("PWPUSH_COM")

    localized do
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

      # Dashboard controller has been removed.  Maintain this remapping for now.
      get "/d/active", to: "passwords#active"
      get "/d/expired", to: "passwords#expired"

      resources :p, controller: :passwords, as: :passwords, except: %i[index edit update] do
        get "preview", on: :member
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
      root to: "passwords#new"
    end
  end

  # This allows for running the application in a subfolder.  See config/settings.yml (relative_root)
  if Settings.relative_root
    scope("#{Settings.relative_root}/:locale") do
      routes_config.call
    end
    # Remap the root to the default locale
    get Settings.relative_root, to: redirect("/#{Settings.relative_root}/#{I18n.default_locale}", status: 302)
  else
    routes_config.call
  end
end
