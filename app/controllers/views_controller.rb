class ViewsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @views = []

    current_user.passwords.each do |p|
      p.views.each { |v| @views.append(v) }
    end
  end

  def show
    @views = current_user.passwords.find_by(url_token: params[:id]).views

    render 'index'
  end
end
