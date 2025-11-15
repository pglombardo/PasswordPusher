module Madmin
  class ApplicationController < Madmin::BaseController
    include SetLocale

    before_action :authenticate_user!
    before_action :authenticate_admin_user

    def authenticate_admin_user
      unless current_user&.admin?
        head :not_found
      end
    end
  end
end
