class DashboardController < ApplicationController
  before_action :authenticate_user!

  def active
    @active_pushes = Password.includes(:views)
                             .where(user_id: current_user.id, expired: false)
                             .paginate(page: params[:page], per_page: 30)
                             .order(created_at: :desc)
  end

  def expired
    @expired_pushes = Password.where(user_id: current_user.id, expired: true)
                              .paginate(page: params[:page], per_page: 30)
                              .order(expired_on: :desc)
  end
end
