class DashboardController < ApplicationController
  acts_as_token_authentication_handler_for User

  def active
    @active_pushes = Password.includes(:views)
                             .where(user_id: current_user.id, expired: false)
                             .paginate(page: params[:page], per_page: 30)
                             .order(created_at: :desc)

    respond_to do |format|
      format.html { }
      format.json {
        json_parts = []
        @active_pushes.each do |push|
          json_parts << push.to_json(owner: true, payload: false)
        end
        render json: "[" + json_parts.join(",") + "]"
      }
    end
  end

  def expired
    @expired_pushes = Password.where(user_id: current_user.id, expired: true)
                              .paginate(page: params[:page], per_page: 30)
                              .order(expired_on: :desc)

    respond_to do |format|
      format.html { }
      format.json {
        json_parts = []
        @expired_pushes.each do |push|
          json_parts << push.to_json(owner: true, payload: false)
        end
        render json: "[" + json_parts.join(",") + "]"
      }
    end
  end
end
