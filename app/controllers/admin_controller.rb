class AdminController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin
  before_action :load_release_check

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

  def load_release_check
    @release_check = ReleaseCheck.cached
  end
end
