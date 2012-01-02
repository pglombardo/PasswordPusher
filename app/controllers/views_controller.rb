class ViewsController < ApplicationController
  def index
    @views = View.all
  end

  def show
    @view = View.find(params[:id])
  end

  def new
    @view = View.new
  end

  def create
    @view = View.new(params[:view])
    if @view.save
      redirect_to @view, :notice => "Successfully created view."
    else
      render :action => 'new'
    end
  end

  def edit
    @view = View.find(params[:id])
  end

  def update
    @view = View.find(params[:id])
    if @view.update_attributes(params[:view])
      redirect_to @view, :notice  => "Successfully updated view."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @view = View.find(params[:id])
    @view.destroy
    redirect_to views_url, :notice => "Successfully destroyed view."
  end
end
