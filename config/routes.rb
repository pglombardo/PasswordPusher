# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"} if ENV.key?("PWPUSH_COM")

  if ENV.key?("PWP_PUBLIC_GATEWAY")
    draw :public_users
    draw :public_pushes

    # Add a route that handles the root path and returns a 404 error
    get "/", to: proc { |env| [404, {"Content-Type" => "text/html"}, ["<h1>Not Found</h1>"]] }
  else
    draw :admin
    draw :users
    draw :pushes
    apipie

    get "/pages/*id" => "pages#show", :as => :page, :format => false
    resources :feedbacks, only: %i[new create]

    draw :legacy_devise
    draw :legacy_feedbacks
    draw :legacy_pages
    draw :legacy_pushes

    root to: "passwords#new"
  end
end
