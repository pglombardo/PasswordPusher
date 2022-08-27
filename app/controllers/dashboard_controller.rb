class DashboardController < ApplicationController
  acts_as_token_authentication_handler_for User

  resource_description do
    short 'View your previously created pushes.'
  end

  api :GET, '/d/active.json', 'Retrieve your active pushes.'
  formats ['json']
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/d/active.json'
  description "Returns the list of pushes that you previously pushed which are still active."
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

  api :GET, '/d/expired.json', 'Retrieve your expired pushes.'
  formats ['json']
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/d/expired.json'
  description "Returns the list of pushes that you previously pushed which have expired."
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
