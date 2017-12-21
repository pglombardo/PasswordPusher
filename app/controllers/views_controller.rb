class ViewsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @views = View.all
  end

  def show
    @view = View.find(params[:id])
  end

  private

  def view_params
    params.require(:view).permit(:password_id, :ip, :user_agent)
  end
end
