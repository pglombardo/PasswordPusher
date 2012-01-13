class ViewsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @views = View.all
  end

  def show
    @view = View.find(params[:id])
  end
end
