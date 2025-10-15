class AdminController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin

  def index
  end

  def welcome
  end

  private

  def require_admin
    unless current_user.admin?
      head :not_found
    end
  end
end
