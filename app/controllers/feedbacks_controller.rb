# frozen_string_literal: true

class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(params[:feedback])

    # spam? will tell us if the hidden field was filled in (it shouldn't be filled in)
    # valid? will tell us if the humanity test was answered correctly
    if @feedback.spam? || !@feedback.valid?
      flash[:alert] =
        _("Our apologies but you failed the spam check.  You could try contacting us on Github instead.")
      render :new, status: :unprocessable_entity
    else
      @feedback.request = request
      if @feedback.deliver
        redirect_to root_path,
          notice: _("Feedback sent!  We will get back to you as soon as possible.")
      else
        flash[:alert] =
          _("Could not send feedback.  Did you pass the Humanity Test?  Valid email?  Try again?")
        render :new, status: :unprocessable_entity
      end
    end
  end
end
