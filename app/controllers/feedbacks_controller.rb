class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(params[:feedback])
    @feedback.request = request
    if @feedback.deliver
      flash.now[:success] = _('Feedback sent!')
    else
      flash.now[:error] = _('Could not send feedback.  Try again?')
      render :new
    end
  end
end
