class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(params[:feedback])

    if @feedback.spam?
      flash.now[:alert] = _('Our apologies but you failed the spam check.  You could try contacting us on Github instead.')
      render :new
    else
      @feedback.request = request
      if @feedback.deliver
        flash.now[:notice] = _('Feedback sent!')
      else
        flash[:alert] = _('Could not send feedback.  Did you pass the Humanity Test?  Valid email?  Try again?')
        render :new
      end
    end
  end
end
