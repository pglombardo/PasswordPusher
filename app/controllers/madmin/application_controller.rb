module Madmin
  class ApplicationController < Madmin::BaseController
    before_action :authenticate_admin_user

    def authenticate_admin_user
      # TODO: Add your authentication logic here

      # For example, with Rails 8 authentication
      # redirect_to "/", alert: "Not authorized." unless authenticated? && Current.user.admin?

      # Or with Devise
      # redirect_to "/", alert: "Not authorized." unless current_user&.admin?
    end
  end
end
