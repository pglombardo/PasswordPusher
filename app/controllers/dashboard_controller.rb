class DashboardController < ApplicationController
    before_action :authenticate_user!

    def overview
    end

    def active
        @active_payloads = Password.where(user_id: current_user.id, expired: false).order(created_at: :desc)
    end

    def expired
        @expired_payloads = Password.where(user_id: current_user.id, expired: true).order(expired_on: :desc)
    end
end
