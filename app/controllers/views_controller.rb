# frozen_string_literal: true

class ViewsController < ApplicationController
  before_action :authenticate_user!

  def index
    @views = View.all
  end

  def show
    @view = View.find(params[:id])
  end
end
