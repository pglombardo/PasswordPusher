# frozen_string_literal: true

Rails.application.routes.draw do
  if ENV.key?("PWP_PUBLIC_GATEWAY")
    draw :public_users
    draw :public_pushes

    # Add a route that handles the root path and returns a 404 error
    root to: proc { |env| [404, {"Content-Type" => "text/html"}, ["<h1>Not Found</h1>"]] }
  else
    draw :admin
    draw :users
    draw :pushes
    draw :pwp_api

    apipie

    get "/pages/*id" => "pages#show", :as => :page, :format => false

    mount Mailbin::Engine => :mailbin if Rails.env.development?

    draw :legacy_devise
    draw :legacy_pages
    draw :legacy_pushes

    root to: "pushes#new"
  end

  # Health check endpoint that returns a simple 200 OK response
  get "/up" => proc { |env|
    [200, {"Content-Type" => "text/html"}, ["<html style='background:green;width:100%;height:100vh'></html>"]]
  }

  post "/csp-violation-report", to: "csp_reports#create"
end
